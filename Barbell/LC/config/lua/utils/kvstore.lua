local KVStore = {}

KVStore.Redis = {}
KVStore.Memcached = {}

KVStore.__index = KVStore
KVStore.Redis.__index = KVStore.Redis
KVStore.Memcached.__index = KVStore.Memcached
setmetatable(KVStore.Redis, KVStore)     -- class inheritance
setmetatable(KVStore.Memcached, KVStore) -- class inheritance

function KVStore:create()
    local s = {}
    setmetatable(s, KVStore)
    return s
end

function KVStore:get(key)
    -- print("GET")
    connection:get(key)
end

function KVStore:set(key, value)
    -- print("SET")
    connection:set(key, value)
end

function KVStore.Redis:create()
    local s = {}
    setmetatable(s, KVStore.Redis)
    return s
end

function KVStore.Redis:get(key)
    print("GET Redis")
    connection:get(key)
end

function KVStore.Redis:set(key, value)
    print("SET Redis");
    connection:set(key, value)
end

function KVStore.Memcached:create()
    local s = {}
    setmetatable(s, KVStore.Memcached)
    return s
end

function KVStore.Memcached.get()
    print("GET Memcached")
end

function KVStore.Memcached.set()
    print("SET Memcached")
end

return KVStore
