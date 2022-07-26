classdef ParcellationMap < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Parcellation siibra.items.Parcellation
        Space siibra.items.Space
        URL string
        CachePath string
    end
    
    methods
        function obj = ParcellationMap(parcellation, space)
            obj.Parcellation = parcellation;
            obj.Space = space;
        end

        function url = get.URL(obj)
            % /atlases/{atlas_id}/spaces/{space_id}/parcellation_maps?parcellation_id={parcellation_id}
            url = strcat("atlases/", obj.Parcellation.Atlas.Id, "/spaces/", obj.Space.Id, "/parcellation_maps?parcellation_id=", obj.Parcellation.Id);
        end
        
        function cachePath = get.CachePath(obj)
            cachePath = strcat("+siibra/cache/parcellation_maps/", obj.Parcellation.Name, "_", obj.Space.Name);
        end

        function nifti = fetch(obj)
            if ~isfolder(obj.CachePath)
                options = weboptions;
                options.Timeout = 30;
                websave(obj.CachePath + ".zip", obj.URL, options);
                unzip(obj.CachePath + ".zip", obj.CachePath)
            end
            files = dir(obj.CachePath + "/*.nii.gz");
            nifti = arrayfun(@(file) siibra.items.NiftiImage(obj.CachePath + "/" + file.name), files);
        end
    end
end

