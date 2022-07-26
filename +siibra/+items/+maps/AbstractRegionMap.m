classdef (Abstract) AbstractRegionMap < matlab.mixin.Heterogeneous & handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    % kn
    
    properties
        Region (1, :) siibra.items.Region
        Space (1, :) siibra.items.Space

    end
    properties (Abstract)
        URL string
        CachePath string
    end
    
    methods
        function obj = AbstractRegionMap(region, space)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            obj.Region = region;
            obj.Space = space;
            
        end

        function nifti = fetch(obj)
            if ~isfile(obj.CachePath)
                % set higher timeout
                options = weboptions;
                options.Timeout = 30;
                nifti_data = webread(siibra.internal.API.absoluteLink(obj.URL));
                file_handle = fopen(obj.CachePath, "w");
                assert(file_handle > 0, "invalid file handle for cached file " + obj.CachePath);
                fwrite(file_handle, nifti_data);
                fclose(file_handle);
            end
            nifti = siibra.items.NiftiImage(obj.CachePath);
        end

        function size = mapSize(obj)
            nifti = obj.fetch();
            size = nifti.Header.ImageSize;
        end
        function data = getDataRelativeToTemplate(obj)
            template = obj.Space.loadTemplate;
            pmapNifti = obj.fetch();
            data = pmapNifti.getOverlayWarpedRelativeTo(template);
        end
    end
end

