module Re2oAPIClients

using HTTP
using Base.Filesystem
using Dates
using Serialization
using JSON

TOKENFILEMANE = joinpath(homedir(), ".re2otoken")

loadtoken(tokenfilename) = deserialize(tokenfilename)
savetoken(token, tokenfilename=TOKENFILEMANE) = serialize(tokenfilename, token)

mutable struct Re2oAPIClient
    hostname::String
    username::String
    password::String
    tokenfilename::String
    use_tls::Bool
    token::Union{Pair{String,DateTime}, Nothing}
    Re2oAPIClient(hostname, username, password, token_file, use_tls, token) = new(hostname, username, password, token_file, use_tls, token)
end

Re2oAPIClient(hostname, username, password; token_file=TOKENFILEMANE, use_tls=true, token=nothing) = 
    Re2oAPIClient(hostname, username, password, token_file, use_tls, token)

get_url_for(client, endpoint) = begin
    proto = if client.use_tls "https" else "http" end
    "$(proto)://$(client.hostname)/api/$(endpoint)"
end

loadservertoken(client::Re2oAPIClient) = begin
    params = Dict(
        "username" => client.username,
        "password" => client.password
    )
    r = HTTP.post(
        get_url_for(client, "token-auth"), 
        ["Content-Type" => "application/json"], 
        JSON.json(params)
    )
    response_body = JSON.parse(String(r.body))
    token = response_body["token"]
    expiration = response_body["expiration"]
    # This is uggly, don't know how to do it otherwise...
    token => DateTime(expiration[1:23])
end
loadservertoken!(client::Re2oAPIClient) = begin
    client.token = loadservertoken(client)
    savetoken(client.token, client.tokenfilename)
end

token!(client) = begin
    rightnow = DateTime(now())
    token = if !isnothing(client.token)
        client.token
    elseif ispath(client.tokenfilename)
        client.token = loadtoken(client.tokenfilename)
    else
        loadservertoken!(client)
    end
    if last(token) > rightnow
        loadservertoken!(client)
    end
    first(token)
end

request(client, method::String, url, params=nothing, headers=[]; kwargs...) = begin
    token = token!(client)
    push!(headers, "Authorization"=>"Token $token")
    
    r = if isnothing(params)
        HTTP.request(
            method,
            url, 
            headers;
            kwargs...
        )
    else
        push!(headers, "Content-Type" => "application/json")
        HTTP.request(
            method,
            url, 
            headers, 
            JSON.json(params);
            kwargs...
        )
    end
    JSON.parse(String(r.body))
end

get(client, url, params=nothing, headers=[]; kwargs...) = request(client, "GET", url, params, headers; kwargs...)
post(client, url, params=nothing, headers=[]; kwargs...) = request(client, "POST", url, params, headers; kwargs...)
delete(client, url, params=nothing, headers=[]; kwargs...) = request(client, "DELETE", url, params, headers; kwargs...)
head(client, url, params=nothing, headers=[]; kwargs...) = request(client, "HEAD", url, params, headers; kwargs...)
option(client, url, params=nothing, headers=[]; kwargs...) = request(client, "OPTION", url, params, headers; kwargs...)
patch(client, url, params=nothing, headers=[]; kwargs...) = request(client, "PATCH", url, params, headers; kwargs...)
put(client, url, params=nothing, headers=[]; kwargs...) = request(client, "PUT", url, params, headers; kwargs...)

list(client, endpoint, max_results=nothing, params=Dict()) = begin
    url = get_url_for(client, endpoint)
    if !("page_size" in keys(params))
        push!(params, "page_size"=>if isnothing(max_results) "all" else max_results end)
    end
    response = get(client, url, params)
    results = response["results"]
    while !isnothing(response["next"]) && (isnothing(max_results) || length(results) < max_results)
        response = get(client, response["next"])
        append!(results, response["results"])
    end
    if !isnothing(max_results) results[1:max_results] else results end
end

export Re2oAPIClient, list

end # module
