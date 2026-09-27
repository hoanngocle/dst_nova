local registry={}
return {
    Register=function(id,prepare) assert(type(prepare)=='function'); registry[id]=prepare end,
    Prepare=function(inst,id,payload)
        if not registry[id] then return nil,'Kỹ năng chưa được đăng ký.' end
        return registry[id](inst,payload)
    end,
}
