classdef LabelledRegionMap < siibra.items.maps.AbstractRegionMap
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    % kn
    
    properties
        URL string
        CachePath string
        LabelIndex (1,1) uint32 {mustBeFinite}
    end
    
    methods
        function obj = LabelledRegionMap(region, space)
            obj@siibra.items.maps.AbstractRegionMap(region, space)
            regionInfo = webread(siibra.internal.API.absoluteLink(obj.infoOrMapURL(true)));
            obj.LabelIndex = regionInfo.label;
        end
        function url = infoOrMapURL(obj, isInfo)
            if isInfo
                endpoint = "info";
            else
                endpoint = "map";
            end
            % /atlases/{atlas_id}/parcellations/{parcellation_id}/regions/{region_id}/regional_map/info?space_id={space_id}&map_type=LABELLED
            url = strcat("atlases/", obj.Region.Parcellation.Atlas.Id, "/parcellations/", obj.Region.Parcellation.Id,...
                "/regions/", obj.Region.Name, "/regional_map/", endpoint, "?space_id=", obj.Space.Id, "&map_type=LABELLED");
        end
        
        function url = get.URL(obj)
            url = obj.infoOrMapURL(false);
            
        end
        function cachePath = get.CachePath(obj)
            cachePath = strcat("+siibra/cache/region_cache/", obj.Region.NormalizedName, obj.Space.NormalizedName, "_labelled.nii.gz");
        end
    end
        
end

