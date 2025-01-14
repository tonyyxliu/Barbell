--
-- Created by IntelliJ IDEA.
-- User: chen0
-- Date: 26/6/2017
-- Time: 12:48 AM
-- To change this template use File | Settings | File Templates.
--

local list = require('list')

local graph = {}
graph.__index = graph

graph.vertex = {}
graph.vertex.__index = graph.vertex

graph.Edge = {}
graph.Edge.__index = graph.Edge

function graph.vertex.create(id, params)
    local v = {}
    setmetatable(v, graph.vertex)
    v.id = id
    v.params = params
    return v
end

function graph.Edge.create(v, w, weight)
    local s = {}
    setmetatable(s, graph.Edge)
    if weight == nil then
        weight = 1.0
    end
    s.v = v
    s.w = w
    s.weight = weight
    return s
end

function graph.Edge:from()
    return self.v
end

function graph.Edge:to()
    return self.w;
end

function graph.Edge:other(x)
    if x == self.v then
        return self.w
    else
        return self.v
    end
end

function graph.init()
    local g = {}
    setmetatable(g, graph)
    g.vertices = {}
    g.edges = {}
    g.count = 0 -- number of vertices
    return g
end

function graph:vertexCount()
    return self.count
end

function graph:addVertex(params)
    local vertex = graph.vertex.create(self.count, params)
    self.count = self.count + 1
    self.vertices[vertex.id] = vertex
    self.edges[vertex.id] = list.ArrayList.create()
    return vertex
end

function graph:adj(v_id)
    return self.edges[v_id]
end

-- TODO
function graph:addEdge(v, w, weight)
    local e = graph.Edge.create(v.id, w.id, weight)
    -- self:addVertex(v)
    -- self:addVertex(w)
    self.edges[e:from()]:add(e)
end

function graph:vertexAt(id)
    return self.vertices[id]
end

-- function graph:removeVertex(v)
--     if self.vertices:contains(v) then
--         self.vertices:remove(v)
--         self.edges[v] = nil
--         for i = 0, self.vertices:size() - 1 do
--             local w = self.vertices:get(i)
--             local adj_w = self.edges[w]
--             for k = 0, adj_w:size() - 1 do
--                 local e = adj_w:get(k)
--                 if e:other(w) == v then
--                     adj_w:removeAt(k)
--                     break
--                 end
--             end
--         end
--     end
-- end

-- function graph:vertices()
--     return self.vertices
-- end

-- function graph:edges()
--     local list = list.ArrayList.create()
--     for i = 0, self.vertices:size() - 1 do
--         local v = self.vertices:get(i)
--         local adj_v = self:adj(v)
--         for i = 0, adj_v:size() - 1 do
--             local e = adj_v:get(i)
--             local w = e:other(v)
--             if self.directed == true or w > v then
--                 list:add(e)
--             end
--         end
--     end

--     return list
-- end

return graph
