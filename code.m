%% 1. Crop point cloud
% ptCloud = pcread('F:/shanghai-img-0.pcd');
% removeInvalidPoints(ptCloud);
% % Get the coordinates of all points in the point cloud
% points = ptCloud.Location;
% idx = points(:, 1) >= 35 & points(:, 1) <= 65;
% % Keep these points
% ptCloud = select(ptCloud, idx);
% % Save the modified point cloud file
% pcwrite(ptCloud, '1.pcd');

%% 2. Read the cropped file and extract points at y-coordinates 88.5 to 91.5
% The y range must be greater than one aperture, otherwise an error will occur
tic;
ptCloud = pcread('11.pcd');
figure
pcshow(ptCloud,"BackgroundColor",[1 1 1]);
xlabel('X(mm)');
ylabel('Y(mm)');
zlabel('Z(mm)');
hold on
PlotCuboid([37,18,33.5],[30,3,3]);
PlotCuboid([37,48,33.5],[30,0.1,3]);
points = ptCloud.Location;
idx = points(:, 2) >=43.5 & points(:, 2) <= 46.5;
%18-21 43-46
%28-31 (misjudged)
ptCloud2 = select(ptCloud, idx);
ptCloud2 = pcdenoise(ptCloud2);  % Filter out noise
projectedPoints = ptCloud2.Location(:, [1, 3]);  % Keep x and z coordinates

%% 3. Extract the point cloud contour (upper boundary); the result is saved in the boundaries array
num_points = ceil([ptCloud2.XLimits(2) - ptCloud2.XLimits(1)]/0.05);  % Number of points after extracting the cross-section from the point cloud cross-section plot
boundaries = zeros(1,num_points); 
X = ptCloud2.XLimits(1):0.05:ptCloud2.XLimits(1)+(num_points-1)*0.05;  % Generate x coordinates for later use
for i = 1:ptCloud2.Count  % Traverse all points in the point cloud
    a = ceil([ptCloud2.Location(i) - ptCloud2.XLimits(1) + 0.0001]/0.05);  % Add a small offset of 0.0001
    if boundaries(a) < ptCloud2.Location(i,3)
        boundaries(a) = ptCloud2.Location(i,3);
    end
end

% Plot
figure
scatter(projectedPoints(:,1), projectedPoints(:,2), 5, 'filled');
hold on
XX = ptCloud2.XLimits(1):0.0001:ptCloud2.XLimits(1)+(num_points-1)*0.05;
Y = spline(X, boundaries, XX);
plot(XX, Y, 'Color', 'k', 'linewidth', 2.0);
xlabel("X")
ylabel("Z")
% title('Schematic of point cloud upper boundary extraction (outliers not removed)');

%% 4. Perform regression on all points
% Perform a regression, calculate the segmentation plane, and represent it in red. The returned coefficients are the slope and intercept of the regression line.
coefficients = polyfit(transpose(ptCloud2.XLimits(1):0.05:ptCloud2.XLimits(1)+(num_points-1)*0.05),transpose(boundaries),1);

%% 5. Find the fitted line equation of the plane surface; the result is saved in coefficients2
% Find the centroid (x_ba,y_ba) of all points above the regression line in step 5, and translate the line upward so that it passes through the centroid.
% Because there are grooves, it is difficult to fit the plane surface, so we need to translate the previously calculated regression line upward.
% You can iterate several times as needed; in the file given this time, one calculation is sufficient.
x_ba = 0;
y_ba = 0;
count = 0;
for i = 1:num_points
    if coefficients(1)*X(i) + coefficients(2) < boundaries(i)
        x_ba = x_ba + ptCloud2.XLimits(1) + (i-1)*0.05;
        y_ba = y_ba + boundaries(i);
        count = count + 1;
        i
    end
end
x_ba = x_ba/count;
y_ba = y_ba/count;
coefficients2 = [coefficients(1) y_ba-coefficients(1)*x_ba];  % Corrected plane, used to fit the machined plate surface, shown in green

%% 6. Remove outliers
% Because we found that some sampled points are much higher than the plate plane, and pcdenoise cannot filter them out,
% we set a threshold ourselves to filter out points far above the plate plane. Here it is set to 0.04.
% This is written simply here and can be developed into an algorithm later.
for i = 1:num_points
    if boundaries(i) - (coefficients2(1) * X(i) + coefficients2(2)) > 0.04
        boundaries(i) = coefficients2(1) * X(i) + coefficients2(2);
    end
end

% Plot and perform cubic spline interpolation
figure
scatter(projectedPoints(:,1), projectedPoints(:,2), 5, [0, 1, 1],'filled');  % Point cloud projection data on the XOZ plane
hold on
% plot(X, boundaries, 'blue');
plot(XX, Y, 'Color', [0.5, 0.5, 0.5], 'linewidth', 2.0);  % Extracted boundary line (outliers not removed)
hold on;
plot(X, coefficients(1)*X+coefficients(2), 'Color', [0, 0.79, 0.34], 'linewidth', 2.0);  % Least-squares fitted line for all boundary points
plot(X, coefficients2(1)*X+coefficients2(2), 'red','linewidth', 2.0);  % Final fitted line after iterative translation
plot(X, boundaries, 'Color', 'k', 'linewidth', 2.0);
plot(x_ba, y_ba, 'o', 'MarkerFaceColor', 'm', 'MarkerSize', 10)
legend('Point cloud XOZ plane projection','Cross-section line(Outliers not removed)','Least-squares fitted line(First calculation)','Least-squares fitted line(After iterations of calculation)','Cross-section line(Outliers removed)', 'The iteration points calculated by the least squares iterative method');
xlabel("X(mm)")
ylabel("Z(mm)")
box on;
% title('Schematic of point cloud upper boundary extraction (floating outliers removed)');

figure
plot(X, boundaries, 'Color', 'k', 'linewidth', 2.0);
hold on;
plot(X, coefficients2(1)*X+coefficients2(2), 'red','linewidth', 2.0);
legend('Boundary extraction line (outliers removed)','Final fitted line after iterative translation');
xlabel("X(mm)")
ylabel("Z(mm)")
% title('Schematic of point cloud upper boundary extraction (floating outliers removed)');

%% 8. Calculate notch positions
% The distance array records the distance from each point to the surface in step 6.
% Because the plate cannot be placed perfectly horizontally, there may be errors.
distance = zeros(1, num_points);  % Distance from each point to the green line
for i = 1:num_points
    distance(i) = abs(coefficients2(1)*X(i) - boundaries(i) + coefficients2(2))/sqrt(1+coefficients2(1)^2);
end

% First calculate the sum of depths of the left-neighborhood point set and the right-neighborhood point set (15 points on each side here), then perform a ratio operation (here divide the right side by the left side).
% If this ratio is large, it means the right side of this point is significantly deeper than the left side, so it is the boundary point of a notch.
% Conversely, if this ratio is very small, it means the left side is significantly deeper than the right side, and it is also a notch boundary point.
% For a flat surface, this ratio should be close to 1.
distance_ratio = zeros(1, num_points - 30);
for i = 16:num_points - 15
    left = sum(distance(i-15:i));
    right = sum(distance(i:i+15));
    distance_ratio(i-15) = log2(right/left);
end
% locs1 represents the indices of the start positions of the 4 notches.
% % Use findpeaks to find peaks. Here 'minpeakheight' represents the minimum peak height, and 'minpeakdistance' represents the minimum interval between peaks.
% [pks1,locs1] = findpeaks(distance_ratio, 'minpeakheight', 5,'minpeakdistance', num_points/(num_gully+2));

[pks,locs] = findpeaks(distance_ratio);
locs = locs + 15;
% Use the AMPD algorithm to find peaks instead
locs1 = AMPD(distance_ratio);
locs1 = locs1 + 15;  % Note that we started calculating from the 16th point

% d = rand(1, 200);
% d = 2 * (d-1/2);
% distance_ratio = [distance_ratio,d];
% X = ptCloud2.XLimits(1):0.05:ptCloud2.XLimits(1)+(num_points+200-1)*0.05;  % Generate x coordinates for later use

% Draw a figure. For clarity, there should be 4 peaks and 4 valleys here, corresponding to the start and end of the 4 notches.
figure
plot(X(16:num_points-15), distance_ratio, 'black','linewidth', 2.0);
hold on
scatter(X(locs),distance_ratio(locs-15), 40, "red", "filled");
xlabel("X(mm)");
ylabel("Depth ratio feature");
% title('Schematic of the left-right neighborhood ratio changing with position; there should be 4 peaks and 4 valleys here');

distance_ratio(locs1-15)

% Reverse the ratio: divide the left side by the right side, and repeat the same operation.
for i = 16:num_points - 15
    left = sum(distance(i-15:i));
    right = sum(distance(i:i+15));
    distance_ratio(i-15) = log2(left/right);
end

% locs2 represents the indices of the end positions of the 4 notches.
% [pks2,locs2] = findpeaks(distance_ratio, 'minpeakheight', 5,'minpeakdistance', num_points/(num_gully+2));
locs2 = AMPD(distance_ratio);
locs2 = locs2 + 15;  % Note that we started calculating from the 16th point

% Draw another figure
figure
plot(X(16:num_points-15), distance_ratio, 'black','linewidth', 2.0);
hold on
scatter(X(locs2),distance_ratio(locs2-15), 40, "red", "filled");
xlabel("X(mm)");
ylabel("Depth ratio feature");

distance_ratio(locs2-15)
% Specify the output Excel file name
filename = 'output.xlsx';  

% Write the array to the Excel file, starting from the first cell by default
writematrix(distance_ratio, filename);

% Verify the effectiveness of the algorithm
if length(locs2) == length(locs1)
    fprintf(The algorithm is effective!');
else
    error('The algorithm went wrong!');
end

%% 9. Calculate groove depth
depth = zeros(1, length(locs1));
fprintf('The depth of each groove is：')
for i = 1:length(locs1)
    [m,p]=max(distance(locs1(i):locs2(i))); 
    depth(i) = m;
    disp(m);
end

%% 10. Calculate groove width
% The groove width is the projection length of the line connecting the two notch points in the plane direction.
width = zeros(1, length(locs1));
fprintf(The width of each groove is：')
for i = 1:length(locs1)
    width(i) = abs(X(locs1(i))-X(locs2(i))) * sqrt(1+coefficients2(1)^2);
    disp(width(i));
end

%% 11. Plot
% Plot;
figure
h1 = plot(X, boundaries, 'black','linewidth', 2.0);
hold on;
%plot(X, coefficients(1)*X+coefficients(2), 'yellow');
h2 = plot(X, coefficients2(1)*X+coefficients2(2), 'red','linewidth', 2.0);
for i = 1:num_points
    if locs1(locs1 == i)  % If i equals a number in the locs1 array
        plot(X(i), boundaries(i), 'o', 'MarkerFaceColor', 'b', 'MarkerSize', 10);  % Notch point, represented by a filled marker
        hold on;
    elseif locs2(locs2 == i) 
        plot(X(i), boundaries(i), 'o', 'MarkerFaceColor', 'm', 'MarkerSize', 10);  % Notch point, represented by a filled marker
        hold on;
    end
end
for i = 1:length(locs1)
    txt = sprintf('Depth: %.4f\n Width: %.4f\n', depth(i), width(i));
    text(X(locs1(i)), boundaries(locs1(i))+0.05,txt);
end
h3 = plot(38, 35, 'o', 'MarkerFaceColor', 'b', 'MarkerSize', 10);
h4 = plot(38, 35, 'o', 'MarkerFaceColor', 'm', 'MarkerSize', 10);
legend([h1 h2 h3 h4],'Cross section line','Fitted line','AMPD first detection point','AMPD second detection point');
xlabel("X(mm)")
ylabel("Z(mm)")



toc;
disp(['time: ',num2str(toc)]);


%% 12. Point cloud processing
% circle = abs(ptCloud.YLimits(2) - ptCloud.YLimits(1));
% radius = circle/(2*pi);
% new_locations = ptCloud.Location;
% 
% for i = 1:length(new_locations)  % Traverse all points in the point cloud
%     d = (new_locations(i,3) - coefficients2(1)*new_locations(i,1) - coefficients2(2))/sqrt(1+coefficients2(1)^2);
%     theta = (new_locations(i,2) - ptCloud.YLimits(1)) / radius;  % Radians
%     r = radius - d;
%     new_locations(i,2) = r * sin(theta);
%     new_locations(i,3) = radius - r * cos(theta);
%     if new_locations(i,3) < r && new_locations(i,2) < 0
%         new_locations(i,3) = new_locations(i,3) + 0.35;
%     end
% end
% ptCloud3 = pointCloud(new_locations);
% pcdenoise(ptCloud3);
% 
% figure
% pcshow(ptCloud3, "BackgroundColor",[1 1 1]);
% axis([35 65 -20 20 -5 35]);
% grid on
% daspect([8 1 1]);
% pcwrite(ptCloud3, 'circle.pcd');

%% AMPD algorithm
function peak_indices = AMPD(data)
    % Implement the AMPD algorithm
    % param data: 1-D array
    % return: array of indices where peaks are located
    
    count = length(data);
    p_data = zeros(size(data), 'int32');
    arr_rowsum = [];
    
    for k = 2:floor(count / 2) + 1   % k is all possible window lengths
        row_sum = 0;
        for i = k : count - k   % Traverse the entire sequence
            if data(i) > data(i - k + 1) && data(i) > data(i + k - 1)
                row_sum = row_sum - 1;  % If this condition is satisfied, row_sum-1
            end
        end
    arr_rowsum(k-1) = row_sum;
    end  
    
    [~, min_index] = min(arr_rowsum);
    max_window_length = min_index; 
    
    for k = 2 : max_window_length + 1
        for i = k : count - k
            if data(i) > data(i - k + 1) && data(i) > data(i + k - 1)
                p_data(i) = p_data(i) + 1;
            end
        end
    end
    peak_indices = find(p_data == max_window_length);
end

function PlotCuboid(originPoint,cuboidSize)
    % Function: draw a cuboid
    % Input:
    %       originPoint: origin of the cuboid, row vector, such as [0,0,0];
    %       cuboidSize: length, width, and height of the cuboid, row vector, such as [10,20,30];
    % Output: cuboid graphic
    
    % Calculate the 8 vertices of the cuboid based on the origin and size
    vertexIndex=[0 0 0;0 0 1;0 1 0;0 1 1;1 0 0;1 0 1;1 1 0;1 1 1];
    vertex=originPoint+vertexIndex.*cuboidSize;
    
    % Define the vertices corresponding to the 6 planes
    facet=[1 2 4 3;1 2 6 5;1 3 7 5;2 4 8 6;3 4 8 7;5 6 8 7];
    
    % Define the colors of the 8 vertices; the colors of the drawn planes are interpolated according to the vertex colors
    color=[1;2;3;4;5;6;7;8];
    
    % Draw and display the image
    % patch draws the image.
    % view(3) displays the image in 3-D space.
    % The rest are settings for the background, etc.
    patch('Vertices',vertex,'Faces',facet,'FaceVertexCData',color,'FaceColor','interp','FaceAlpha',0.5);
    view(3);
    xlabel('X(mm)');
    ylabel('Y(mm)');
    zlabel('Z(mm)');
    fig=gcf;
    fig.Color=[1 1 1];
    fig.Name='cuboid';
    fig.NumberTitle='off';
end
