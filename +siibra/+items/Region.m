classdef Region < handle
    properties
        Name string
        NormalizedName string
        Parcellation (1, :) siibra.items.Parcellation
        Spaces (1, :) siibra.items.Space
        Parent (1, 1) % Region
        Children (1, :) % Region
    end
    methods
        function region = Region(name, parcellation, dataset_specs)
            region.Name = name;
            region.Parcellation = parcellation;
            spaces = siibra.items.Space.empty;
            % parse dataset_specs for this region
            if ~isempty(dataset_specs)
                for i = 1:numel(dataset_specs)
                    if iscell(dataset_specs)
                        specs = dataset_specs{i};
                    else
                        specs = dataset_specs(i);
                    end
                    if isfield(specs, "space_id")
                        for spaceIndex = 1:numel(parcellation.Spaces)
                             space = parcellation.Spaces(spaceIndex);
                             if specs.space_id == space.Id
                                spaces(end + 1) = space;
                                
                             end
                        end
                    end
                end
            end
            region.Spaces = spaces;
        end
        function normalizedRegionName = get.NormalizedName(obj)
            normalizedRegionName = strrep(obj.Name, " ", "");
            normalizedRegionName = strrep(normalizedRegionName, "/", "-");
        end
        function space = space(obj, spaceName)
            spaceNames = {obj.Spaces.Name};
            spaceIndex = siibra.internal.fuzzyMatching(spaceName, spaceNames);
            space = obj.Spaces(spaceIndex);
        end
        function children = get.Children(obj)
            children = obj.Parcellation.getChildRegions(obj.Name);
        end
        function parent = get.Parent(obj)
            parent = obj.Parcellation.getParentRegion(obj.Name);
        end
        function map = continuousMap(obj, spaceName)
            space = obj.space(spaceName);
            map = siibra.items.maps.ContinuousRegionMap(obj, space);
        end
        function mask = labelledMap(obj, spaceName)
            space = obj.space(spaceName);
            mask = siibra.items.maps.LabelledRegionMap(obj, space);
        end
    end
end