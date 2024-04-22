function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'ninwb', 'ninwb');
end
obj = schemaObject;
end
