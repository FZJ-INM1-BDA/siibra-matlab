classdef ContinuousRegionMap < siibra.items.maps.AbstractRegionMap
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    % 
    
    properties
        URL string
        CachePath string
    end
    
    methods
        function obj = ContinuousRegionMap(region, space)
            obj@siibra.items.maps.AbstractRegionMap(region, space)
        end
        
        function url = get.URL(obj)
            % /atlases/{atlas_id}/parcellations/{parcellation_id}/regions/{region_id}/regional_map/info
            url = strcat("atlases/", obj.Region.Parcellation.Atlas.Id, "/parcellations/", obj.Region.Parcellation.Id,...
                    "/regions/", obj.Region.Name, "/regional_map/map?space_id=", obj.Space.Id);
        end
        function cachePath = get.CachePath(obj)
            cachePath = strcat("+siibra/cache/region_cache/", obj.Region.NormalizedName, obj.Space.NormalizedName, "_continuous.nii.gz");
        end
    end
end

