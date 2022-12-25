% Import the image of the steel plates
original_img = imread('path-to-image.jpg');
subplot(1,2,1)
imshow(original_img),title("Original Image");

% Convert the image to grayscale
grayscale_img = im2gray(original_img);

% Create binary mask of image
binary_masked_img = edge(grayscale_img,'sobel',(graythresh(grayscale_img)*.1));

% Use morphological opening to remove small noise and smooth the image
se90 = strel('line',3,90);
se0 = strel('line',3,0);
dilated_img = imdilate(binary_masked_img,[se90 se0]);

% Use mask to fill the small holes created to make processing easier
filled_img = imfill(dilated_img,'holes');

% Remove connected objects on the border of the segmented part
no_border_img = imclearborder(filled_img,4);

% Use morphological opening to remove small noise and smooth the image
se = strel('diamond',1);
smoothen_img = imerode(no_border_img,se);
smoothen_img = imerode(smoothen_img,se);
smoothen_img = imerode(smoothen_img,se);
opened_img = imopen(smoothen_img,strel('square', 1));

% Use Canny edge detection to find the edges of the objects
edges = edge(opened_img, 'Canny');

% Use connected component analysis to identify the objects in the image
cc = bwconncomp(edges);

% Loop over the connected components and analyze each one
for i = 1:cc.NumObjects
    % Extract the current component
    component = cc.PixelIdxList{i};

    % Compute the area and perimeter of the component
    area = length(component);
    perimeter = bwarea(bwperim(component));

    % Compute the circularity of the component
    circularity = (4 * pi * area) / perimeter^2;

    % Determine the type of defect based on the computed values
    if area < 30
        type = "Dot";
     elseif circularity < 0.3 && area > 30
        type = "Blowhole";
     elseif circularity > 0.3
         type = "Scratch";
    end

    % Compute the bounding box of the component
    [row, col] = ind2sub(cc.ImageSize, component);
    bbox = [min(col), min(row), max(col) - min(col), max(row) - min(row)];
    % Draw the bounding box and label on the original image
    drawn_img = insertShape(uint8(original_img), 'Rectangle', bbox, 'LineWidth', 2);
    original_img = insertText(uint8(drawn_img), bbox(1:2), type, 'FontSize', 14);

    % Display the image with bounding boxes and labels
    subplot(1,2,2);
    imshow(drawn_img),title("Defects Detected:");
end
