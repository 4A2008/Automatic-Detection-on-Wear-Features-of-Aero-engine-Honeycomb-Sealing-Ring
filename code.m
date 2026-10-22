%% 1.裁剪点云
% ptCloud = pcread('F:/shanghai-img-0.pcd');
% removeInvalidPoints(ptCloud);
% % 获取点云中所有点的坐标
% points = ptCloud.Location;
% idx = points(:, 1) >= 35 & points(:, 1) <= 65;
% % 保留这些点
% ptCloud = select(ptCloud, idx);
% % 保存修改后的点云文件
% pcwrite(ptCloud, '1.pcd');

%% 2.读入剪切之后的文件，截取在y坐标88.5到91.5处的点
% y的范围必须大于1个孔径，否则会出错
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
%28-31(误判)
ptCloud2 = select(ptCloud, idx);
ptCloud2 = pcdenoise(ptCloud2);  % 滤除噪声
projectedPoints = ptCloud2.Location(:, [1, 3]);  % 保留x，z维度的坐标

%% 3.提取点云轮廓（上边界），结果保存在boundaries数组中
num_points = ceil([ptCloud2.XLimits(2) - ptCloud2.XLimits(1)]/0.05);  % 点云截面图提取截面之后的点数
boundaries = zeros(1,num_points); 
X = ptCloud2.XLimits(1):0.05:ptCloud2.XLimits(1)+(num_points-1)*0.05;  % 生成x坐标备用
for i = 1:ptCloud2.Count  % 遍历点云中的所有点
    a = ceil([ptCloud2.Location(i) - ptCloud2.XLimits(1) + 0.0001]/0.05);  % 加一个小偏置0.0001
    if boundaries(a) < ptCloud2.Location(i,3)
        boundaries(a) = ptCloud2.Location(i,3);
    end
end

% 画图
figure
scatter(projectedPoints(:,1), projectedPoints(:,2), 5, 'filled');
hold on
XX = ptCloud2.XLimits(1):0.0001:ptCloud2.XLimits(1)+(num_points-1)*0.05;
Y = spline(X, boundaries, XX);
plot(XX, Y, 'Color', 'k', 'linewidth', 2.0);
xlabel("X")
ylabel("Z")
% title('点云上边界提取示意图（未删除离群点）');

%% 4.对所有点求回归
% 来一手回归，计算分割平面并用红色表示，返回coefficients是回归直线的斜率和截距
coefficients = polyfit(transpose(ptCloud2.XLimits(1):0.05:ptCloud2.XLimits(1)+(num_points-1)*0.05),transpose(boundaries),1);

%% 5.求平面表面的拟合直线方程，结果保存在coefficients2中
% 求5中在回归直线以上部分的所有点的质心(x_ba,y_ba)，把直线向上平移使其过质心
% 因为有凹槽不好拟合平面表面，所以我们要把前面计算的回归直线上平移
% 可以视情况多迭代几次，在本次给定的文件下一次计算足够
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
coefficients2 = [coefficients(1) y_ba-coefficients(1)*x_ba];  % 修正后的平面，用来拟合加工板表面，用绿色表示

%% 6.去除离群点
% 因为我们发现有的采样点远高于平板平面，而且pcdenoise滤除不掉
% 所以我们自己设定一个阈值把远高于平板平面的点滤除掉，这里设置为0.04
% 这里写的比较简单，后面可以再开发算法
for i = 1:num_points
    if boundaries(i) - (coefficients2(1) * X(i) + coefficients2(2)) > 0.04
        boundaries(i) = coefficients2(1) * X(i) + coefficients2(2);
    end
end

% 画图，并作三次样条插值
figure
scatter(projectedPoints(:,1), projectedPoints(:,2), 5, [0, 1, 1],'filled');  % 点云XOZ平面投影数据
hold on
% plot(X, boundaries, 'blue');
plot(XX, Y, 'Color', [0.5, 0.5, 0.5], 'linewidth', 2.0);  % 边界提取线（未去除离群点）
hold on;
plot(X, coefficients(1)*X+coefficients(2), 'Color', [0, 0.79, 0.34], 'linewidth', 2.0);  % 边界线所有点最小二乘拟合线
plot(X, coefficients2(1)*X+coefficients2(2), 'red','linewidth', 2.0);  % 经迭代平移的最终拟合线
plot(X, boundaries, 'Color', 'k', 'linewidth', 2.0);
plot(x_ba, y_ba, 'o', 'MarkerFaceColor', 'm', 'MarkerSize', 10)
legend('Point cloud XOZ plane projection','Cross-section line(Outliers not removed)','Least-squares fitted line(First calculation)','Least-squares fitted line(After iterations of calculation)','Cross-section line(Outliers removed)', 'The iteration points calculated by the least squares iterative method');
xlabel("X(mm)")
ylabel("Z(mm)")
box on;
% title('点云上边界提取示意图（已删除漂浮离群点）');

figure
plot(X, boundaries, 'Color', 'k', 'linewidth', 2.0);
hold on;
plot(X, coefficients2(1)*X+coefficients2(2), 'red','linewidth', 2.0);
legend('边界提取线（去除离群点）','经迭代平移的最终拟合线');
xlabel("X(mm)")
ylabel("Z(mm)")
% title('点云上边界提取示意图（已删除漂浮离群点）');

%% 8.计算豁口位置
% distance数组记录每个点到6中表面的距离
% 因为平板摆放不可能完全水平，可能会有误差
distance = zeros(1, num_points);  % 每个点到绿线的距离
for i = 1:num_points
    distance(i) = abs(coefficients2(1)*X(i) - boundaries(i) + coefficients2(2))/sqrt(1+coefficients2(1)^2);
end

% 先计算点的左邻域点集，右邻域点集的深度之和（这里两侧各取15个点），然后做比值运算（这里拿右边除左边）。
% 如果这个比值很大，说明此点右侧显著的比左侧深，它就是豁口的分界点；
% 反之如果这个比值很小，说明左侧显著比右侧深，它也是豁口分界点。
% 如果是平面，这个比值应该接近于1.
distance_ratio = zeros(1, num_points - 30);
for i = 16:num_points - 15
    left = sum(distance(i-15:i));
    right = sum(distance(i:i+15));
    distance_ratio(i-15) = log2(right/left);
end
% locs1代表着4个豁口开始位置的索引
% % 利用findpeaks寻找峰值，这里'minpeakheight'代表最小峰值，'minpeakdistance'代表最小峰与峰之间的间隔
% [pks1,locs1] = findpeaks(distance_ratio, 'minpeakheight', 5,'minpeakdistance', num_points/(num_gully+2));

[pks,locs] = findpeaks(distance_ratio);
locs = locs + 15;
% 改用AMPD算法寻找峰值
locs1 = AMPD(distance_ratio);
locs1 = locs1 + 15;  % 注意到我们是从第16个点开始计算的

% d = rand(1, 200);
% d = 2 * (d-1/2);
% distance_ratio = [distance_ratio,d];
% X = ptCloud2.XLimits(1):0.05:ptCloud2.XLimits(1)+(num_points+200-1)*0.05;  % 生成x坐标备用

% 画个图，为了说明白，这里应该有4个波峰和4个波谷，分别对应4个豁口的开始和结束
figure
plot(X(16:num_points-15), distance_ratio, 'black','linewidth', 2.0);
hold on
scatter(X(locs),distance_ratio(locs-15), 40, "red", "filled");
xlabel("X(mm)");
ylabel("Depth ratio feature");
% title('左右邻域比值随位置变化示意图，这里应该有4个波峰和4个波谷');

distance_ratio(locs1-15)

% 再反过来，拿左边除以右面，相同的操作再来一遍
for i = 16:num_points - 15
    left = sum(distance(i-15:i));
    right = sum(distance(i:i+15));
    distance_ratio(i-15) = log2(left/right);
end

% locs2代表着4个豁口结束位置的索引
% [pks2,locs2] = findpeaks(distance_ratio, 'minpeakheight', 5,'minpeakdistance', num_points/(num_gully+2));
locs2 = AMPD(distance_ratio);
locs2 = locs2 + 15;  % 注意到我们是从第16个点开始计算的

% 再画个图
figure
plot(X(16:num_points-15), distance_ratio, 'black','linewidth', 2.0);
hold on
scatter(X(locs2),distance_ratio(locs2-15), 40, "red", "filled");
xlabel("X(mm)");
ylabel("Depth ratio feature");

distance_ratio(locs2-15)
% 指定输出的Excel文件名  
filename = 'output.xlsx';  

% 将数组写入Excel文件，默认从第一个单元格开始  
writematrix(distance_ratio, filename);

% 验证算法有效性
if length(locs2) == length(locs1)
    fprintf('算法有效！');
else
    error('算法出错');
end

%% 9.计算槽深
depth = zeros(1, length(locs1));
fprintf('每条沟的深度是：')
for i = 1:length(locs1)
    [m,p]=max(distance(locs1(i):locs2(i))); 
    depth(i) = m;
    disp(m);
end

%% 10.计算槽宽
% 槽宽是两个槽口点连线距离在平面方向上的投影长度
width = zeros(1, length(locs1));
fprintf('每条沟的宽度是：')
for i = 1:length(locs1)
    width(i) = abs(X(locs1(i))-X(locs2(i))) * sqrt(1+coefficients2(1)^2);
    disp(width(i));
end

%% 11.画图
% 画图;
figure
h1 = plot(X, boundaries, 'black','linewidth', 2.0);
hold on;
%plot(X, coefficients(1)*X+coefficients(2), 'yellow');
h2 = plot(X, coefficients2(1)*X+coefficients2(2), 'red','linewidth', 2.0);
for i = 1:num_points
    if locs1(locs1 == i)  % 如果i等于数组locs1里面的数字
        plot(X(i), boundaries(i), 'o', 'MarkerFaceColor', 'b', 'MarkerSize', 10);  % 豁口点，用实心点表示
        hold on;
    elseif locs2(locs2 == i) 
        plot(X(i), boundaries(i), 'o', 'MarkerFaceColor', 'm', 'MarkerSize', 10);  % 豁口点，用实心点表示
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
disp(['运行时间: ',num2str(toc)]);


%% 12.点云处理
% circle = abs(ptCloud.YLimits(2) - ptCloud.YLimits(1));
% radius = circle/(2*pi);
% new_locations = ptCloud.Location;
% 
% for i = 1:length(new_locations)  % 遍历点云中的所有点
%     d = (new_locations(i,3) - coefficients2(1)*new_locations(i,1) - coefficients2(2))/sqrt(1+coefficients2(1)^2);
%     theta = (new_locations(i,2) - ptCloud.YLimits(1)) / radius;  %弧度制
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

%% AMPD算法
function peak_indices = AMPD(data)
    % 实现AMPD算法
    % param data: 1-D 数组
    % return: 波峰所在索引值的数组
    
    count = length(data);
    p_data = zeros(size(data), 'int32');
    arr_rowsum = [];
    
    for k = 2:floor(count / 2) + 1   % k是所有可能的窗口长度
        row_sum = 0;
        for i = k : count - k   % 遍历整个序列
            if data(i) > data(i - k + 1) && data(i) > data(i + k - 1)
                row_sum = row_sum - 1;  % 满足这个条件row_sum-1  
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
    % 函数功能： 绘制长方体
    % 输入：
    %       originPoint：长方体的原点,行向量，如[0，0，0];
    %       cuboidSize：长方体的长宽高,行向量，如[10，20，30];
    % 输出：长方体图形
    
    % 根据原点和尺寸，计算长方体的8个的顶点
    vertexIndex=[0 0 0;0 0 1;0 1 0;0 1 1;1 0 0;1 0 1;1 1 0;1 1 1];
    vertex=originPoint+vertexIndex.*cuboidSize;
    
    % 定义6个平面分别对应的顶点
    facet=[1 2 4 3;1 2 6 5;1 3 7 5;2 4 8 6;3 4 8 7;5 6 8 7];
    
    % 定义8个顶点的颜色，绘制的平面颜色根据顶点的颜色进行插补
    color=[1;2;3;4;5;6;7;8];
    
    % 绘制并展示图像
    % patch 对图像进行绘制。
    % view(3) 将图像放到三维空间中展示。
    % 其余的是设置背景等等
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





