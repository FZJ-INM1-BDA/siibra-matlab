classdef Parcellation < handle
    properties
        Id (1, 1) string
        Name (1, 1) string
        Atlas (1, :) siibra.items.Atlas
        Modality % no consistent type yet
        Desciption (1, 1) string
        RegionTree (1, 1) digraph
        Spaces (1, :) siibra.items.Space
    end

    methods
        function parcellation = Parcellation(parcellation_json, atlas)
            parcellation.Id = strcat(parcellation_json.id.kg.kgSchema, '/', parcellation_json.id.kg.kgId);
            parcellation.Name = parcellation_json.name;
            parcellation.Atlas = atlas;
            parcellation.Modality = parcellation_json.modality;
            if ~ isempty(parcellation_json.infos)
                parcellation.Desciption = parcellation_json.infos(1).description;
            end

            % link spaces from atlas
            parcellation.Spaces = siibra.items.Space.empty;
            % retrieve available spaces from atlas
            for idx = 1:numel(parcellation_json.availableSpaces)
                % store handle to space object
                for atlas_space_index = 1:numel(atlas.Spaces)
                    if isequal(atlas.Spaces(atlas_space_index).Id, parcellation_json.availableSpaces(idx).id)
                        parcellation.Spaces(end +1) = atlas.Spaces(atlas_space_index);
                    end
                end
            end
            
            % call api to get parcellation tree
            regions = webread(parcellation_json.links.regions.href);
            
            % store graph
            parcellation.RegionTree = siibra.items.Parcellation.createParcellationTree(parcellation, regions);
            
            %parcellation.Spaces = table(string({spaces_subset.Name}).', spaces_subset.', 'VariableNames', {'Name', 'Space'});
        end
       
        function region_names = findRegion(obj, region_name_query)
            region_names = obj.RegionTree.Nodes(contains(obj.RegionTree.Nodes.Name, region_name_query), 1);
        end
        function region = decodeRegion(obj, region_name_query)
            region_table = obj.findRegion(region_name_query);
            assert(height(region_table) == 1, "query was not unambiguous!")
            region = region_table.Region(1);
        end
        function region = getRegion(obj, region_name_query)
            nodeId = obj.RegionTree.findnode(region_name_query);
            region = obj.RegionTree.Nodes.Region(nodeId);
        end
        function children = getChildRegions(obj, region_name)
            nodeId = obj.RegionTree.findnode(region_name);
            childrenIds = obj.RegionTree.successors(nodeId);
            children = obj.RegionTree.Nodes.Region(childrenIds);
        end
        function parent_region = getParentRegion(obj, region_name)
            nodeId = obj.RegionTree.findnode(region_name);
            parents = obj.RegionTree.predecessors(nodeId);
            assert(length(parents) == 1, "Expect just one parent in a tree structure");
            parentId = parents(1);
            parent_region = obj.RegionTree.Nodes.Region(parentId);
        end
        function results = assign(obj, point)
            spaceIndex = find(strcmp([obj.Spaces.Name], point.Space.Name));
            assert(~isempty(spaceIndex), "Space of point is not supported by this parcellation!");
            template = obj.Spaces(spaceIndex).Template;
            template_output_view = template.getOutputView();
            [voxelPositionOfPointX, voxelPositionOfPointY, voxelPositionOfPointZ]  = template_output_view.worldToIntrinsic(point.Position(1), point.Position(2), point.Position(3));
            voxelPositionOfPointX = round(voxelPositionOfPointX)
            voxelPositionOfPointY = round(voxelPositionOfPointY)
            voxelPositionOfPointZ = round(voxelPositionOfPointZ)
            % first pass to find out how many regions in this parcellation 
            % support this space
            nRegions = 0;
            regionMask = zeros(length(obj.RegionTree.Nodes.Region), 'logical');
            for i = 1:length(obj.RegionTree.Nodes.Region)
                region = obj.RegionTree.Nodes.Region(i);
                if any(strcmp([region.Spaces.Name], point.Space.Name))
                    nRegions = nRegions + 1;
                    regionMask(i) = true;
                end  
            end

            completeMap = zeros([template.Size, nRegions]);
            regionIndex = 1;
            for i = 1:length(obj.RegionTree.Nodes.Region)
                region = obj.RegionTree.Nodes.Region(i);
                if any(strcmp([region.Spaces.Name], point.Space.Name))
                    pmap = region.probabilityMap(point.Space.Name);
                    completeMap(:, :, :, regionIndex) = pmap.Map;
                    regionIndex = regionIndex + 1;
                end
            end
            
            regionProbabilities = completeMap(voxelPositionOfPointX, voxelPositionOfPointY, voxelPositionOfPointZ, :);
             % regionsSupportingSpace = obj.RegionTree.Nodes.Region(regionMask);
            relevantRegions = regionProbabilities > 0;
            results = regionProbabilities(relevantRegions);
        end
    end
    

    methods (Static)
        function tree = createParcellationTree(parcellation, regions)
            root.name = parcellation.Name;
            root.children = regions;
            [source, target, region] = siibra.items.Parcellation.traverseTree(parcellation, root, string.empty, string.empty, siibra.items.Region.empty);
            % append root node
            nodes = target;
            nodes(length(nodes) + 1) = root.name;
            region(length(region) + 1) = siibra.items.Region(root.name, parcellation, []);
            % make nodes unique
            [unique_nodes, unique_indices, ~] = unique(nodes);
            nodeTable = table(unique_nodes.', region(unique_indices).', 'VariableNames', ["Name", "Region"]);
            tree = digraph(source, target, zeros(length(target), 1),  nodeTable);
        end

        function [source, target, regions] = traverseTree(parcellation, root, source, target, regions)
            % Parses the parcellation tree.
            % Recursively calls itself to parse the children of the current
            % root.
            % Creates a region for each node in the parcellation tree.

            for child_num = 1:numel(root.children)
                child = root.children(child_num);
                source(length(source) + 1) = root.name;
                target(length(target) + 1) = child.name;
                regions(length(regions) + 1) = siibra.items.Region(child.name, parcellation, child.x_dataset_specs);
                [source, target, regions] = siibra.items.Parcellation.traverseTree(parcellation, child, source, target, regions);
            end
        end
    end
end