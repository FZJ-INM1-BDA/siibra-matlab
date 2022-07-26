classdef Space < handle
    
    properties
        Id (1, 1) string
        Name (1, 1) string
        NormalizedName (1, 1) string
        TemplateURL (1, 1) string
        Format (1, 1) string
        VolumeType (1, 1) string
        AtlasId (1, 1) string
    end
    
    methods
        function space = Space(atlas_space_reference_json, atlas_id)
            space.AtlasId = atlas_id;
            space_json = webread(atlas_space_reference_json.links.self.href);
            space.Id = space_json.id;
            space.Name = space_json.name;
            space.Format = space_json.type;
            space.VolumeType = space_json.src_volume_type;
            space.TemplateURL = space_json.links.templates.href;
        end
        function normalizedName = get.NormalizedName(obj)
            normalizedName = strrep(obj.Name, " ", "");
        end
        function niftiImage = loadTemplate(obj)
            cached_path = strcat("+siibra/cache/template_cache/", obj.Name, ".nii");
            if ~isfile(cached_path)
                options = weboptions;
                options.Timeout = 30;
                websave(cached_path, obj.TemplateURL, options);
            end
            niftiImage = siibra.items.NiftiImage(cached_path);
        end
    end
end