classdef Task3_2220165_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        ParameterEditField_3       matlab.ui.control.NumericEditField
        ParameterEditField_3Label  matlab.ui.control.Label
        ParameterSlider_3          matlab.ui.control.Slider
        ParameterSlider_3Label     matlab.ui.control.Label
        LoadSecondImageButton      matlab.ui.control.Button
        ParameterEditField_2       matlab.ui.control.NumericEditField
        ParameterEditField_2Label  matlab.ui.control.Label
        ParameterSlider_2          matlab.ui.control.Slider
        ParameterSlider_2Label     matlab.ui.control.Label
        AddFilterButton            matlab.ui.control.Button
        SelectTemplateButton       matlab.ui.control.Button
        ResetButton                matlab.ui.control.Button
        ParameterEditField         matlab.ui.control.NumericEditField
        ParameterEditFieldLabel    matlab.ui.control.Label
        ParameterSlider            matlab.ui.control.Slider
        ParameterSliderLabel       matlab.ui.control.Label
        OperationDropDown          matlab.ui.control.DropDown
        OperationLabel             matlab.ui.control.Label
        LoadImageButton            matlab.ui.control.Button
        UIAxes_2                   matlab.ui.control.UIAxes
        UIAxes                     matlab.ui.control.UIAxes
    end

        
    properties (Access = private)
        OriginalImage  % Store the original image data
        ProcessedImage % Store the processed image data
        OriginalImageColormap % Store original image colormap for indexed images
        CurrentImageHandle % Handle for the image in ProcessedAxes
        FilterChain = {}   % Cell array storing stacked filters
        TemplateImage % NEW: Stores the actual cropped template image
        % Store the list of operations centrally for easy access (RESTORED)
        OperationList = { ...
            'None', ...
            'Image Enhancement (Gamma Correction)', ...
            'Image Enhancement (Histogram Equalization)', ...
            'Image Enhancement (Brightness Adjustment)', ...
            'Spatial Smoothing (Box)', ...
            'Spatial Smoothing (Weighted Average)', ...
            'Spatial Smoothing (Median)', ...
            'Spatial Sharpening (Laplacian)', ...
            'Spatial Sharpening (Boosting)', ...
            'Spatial Sharpening (Sobel Horizontal)', ...
            'Spatial Sharpening (Sobel Vertical)', ...
            'Spatial Sharpening (Prewitt Horizontal)', ...
            'Spatial Sharpening (Prewitt Vertical)', ...
            'Frequency Smoothing (Ideal Low-pass)', ...
            'Frequency Smoothing (Butterworth Low-pass)', ...
            'Frequency Smoothing (Gaussian Low-pass)', ...
            'Frequency Sharpening (Ideal High-pass)', ...
            'Frequency Sharpening (Butterworth High-pass)', ...
            'Frequency Sharpening (Gaussian High-pass)', ...
            'Color Space (HSI)', ...
            'Color Space (L*a*b*)', ...
            'Color Space (YCbCr)' ...
            'Pyramids (Gaussian)' ...
            'Pyramids (Laplacian)'...
            'Template Matching'...
            'Filter Banks (Gabor)'...
            'Edge Detection (Sobel)'...
            'Edge Detection (Canny)'...
            'Edge Detection (Prewitt)'...
            'Corner Detection (Harris)'...
            'Corner Detection (FAST)',...
            'DoG (Difference of Gaussian)', ...
            'LoG (Laplacian of Gaussian)', ...
            'HoG (Histogram of Oriented Gradients)', ...
            'Hough Transform (Cirles)', ...
            'RANSAC (Line Detection)', ...
            'RANSAC (Circle Detection)', ...
            'Stereo Vision (Epipolar Line)' ...
        };
        SecondImage % Description
    end
    
    methods (Access = private)
        %% 1. SHOW STEREO WARNING (for poor images/matches)
        function showStereoWarning(app, I1, I2, warningMsg)
            % Display two images side-by-side with a warning message
            % Inputs: I1, I2 - the two images, warningMsg - text to display
            
            % Create side-by-side display
            stereoPair = [I1, I2];
            xOffset = size(I1, 2);
            
            imshow(stereoPair, 'Parent', app.UIAxes_2);
            hold(app.UIAxes_2, 'on');
            
            % Add warning header
            text(app.UIAxes_2, xOffset/2, 30, ...
                '⚠️ STEREO WARNING', ...
                'Color', 'yellow', 'FontSize', 14, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', 'BackgroundColor', 'black');
            
            % Add warning message
            text(app.UIAxes_2, xOffset/2, 70, ...
                warningMsg, ...
                'Color', 'white', 'FontSize', 11, ...
                'HorizontalAlignment', 'center', 'BackgroundColor', 'black');
            
            % Add helpful instructions
            text(app.UIAxes_2, xOffset/2, size(I1,1)-80, ...
                {'For best results:', ...
                 '1. Use LEFT and RIGHT images of same scene', ...
                 '2. Images should have good texture/features', ...
                 '3. Ensure camera moved horizontally', ...
                 '4. Try different image pair'}, ...
                'Color', 'cyan', 'FontSize', 10, ...
                'HorizontalAlignment', 'center', 'BackgroundColor', 'black');
            
            hold(app.UIAxes_2, 'off');
            title(app.UIAxes_2, 'Stereo Pair - Needs Better Images');
        end
        
        %% 2. SHOW STEREO RESULTS (successful processing)
        function showStereoResults(app, I1, I2, pts1, pts2, fMatrix, inliers)
            % Display stereo results with matches and epipolar lines
            % Inputs: I1, I2 - images, pts1, pts2 - point locations
            %         fMatrix - fundamental matrix, inliers - logical array
            
            % Create side-by-side display
            stereoPair = [I1, I2];
            xOffset = size(I1, 2);
            
            imshow(stereoPair, 'Parent', app.UIAxes_2);
            hold(app.UIAxes_2, 'on');
            
            % Get inlier points
            inlierPts1 = pts1(inliers, :);
            inlierPts2 = pts2(inliers, :);
            
            % Draw matching lines (limit to 30 for clarity)
            numLines = min(30, size(inlierPts1, 1));
            for i = 1:numLines
                plot(app.UIAxes_2, ...
                    [inlierPts1(i,1), inlierPts2(i,1) + xOffset], ...
                    [inlierPts1(i,2), inlierPts2(i,2)], ...
                    'y-', 'LineWidth', 1);
            end
            
            % Draw inlier points
            plot(app.UIAxes_2, inlierPts1(:,1), inlierPts1(:,2), ...
                'go', 'MarkerSize', 8, 'LineWidth', 1.5);
            plot(app.UIAxes_2, inlierPts2(:,1) + xOffset, inlierPts2(:,2), ...
                'go', 'MarkerSize', 8, 'LineWidth', 1.5);
            
            % Draw epipolar lines (limit to 15)
            numEpilines = min(15, size(inlierPts1, 1));
            if numEpilines > 0
                % Lines in left image from right points
                epiLinesLeft = epipolarLine(fMatrix', inlierPts2(1:numEpilines, :));
                borderPts = lineToBorderPoints(epiLinesLeft, size(I1));
                for i = 1:numEpilines
                    line(app.UIAxes_2, borderPts(i, [1,3]), borderPts(i, [2,4]), ...
                        'Color', 'cyan', 'LineWidth', 1, 'LineStyle', '--');
                end
                
                % Lines in right image from left points
                epiLinesRight = epipolarLine(fMatrix, inlierPts1(1:numEpilines, :));
                borderPts = lineToBorderPoints(epiLinesRight, size(I2));
                for i = 1:numEpilines
                    line(app.UIAxes_2, borderPts(i, [1,3]) + xOffset, borderPts(i, [2,4]), ...
                        'Color', 'cyan', 'LineWidth', 1, 'LineStyle', '--');
                end
            end
            
            % Add statistics text
            statsText = sprintf('Matches: %d\nInliers: %d (%.0f%%)', ...
                size(pts1, 1), sum(inliers), 100*sum(inliers)/length(inliers));
            
            text(app.UIAxes_2, 20, 30, statsText, ...
                'Color', 'white', 'FontSize', 10, 'FontWeight', 'bold', ...
                'BackgroundColor', 'black');
            
            hold(app.UIAxes_2, 'off');
            title(app.UIAxes_2, 'Stereo Vision - Epipolar Geometry');
        end
        
        %% 3. SHOW STEREO ERROR (general error display)
        function showStereoError(app, I, errMsg)
            % Display error message for stereo processing failure
            
            imshow(I, 'Parent', app.UIAxes_2);
            
            % Extract just the error message part
            if contains(errMsg, ':')
                shortErr = extractAfter(errMsg, ':');
                shortErr = strtrim(shortErr);
            else
                shortErr = errMsg;
            end
            
            text(app.UIAxes_2, 0.5, 0.5, ...
                {'Stereo Processing Failed!', ...
                 '', ...
                 ['Error: ' shortErr], ...
                 '', ...
                 'Try loading different images'}, ...
                'Units', 'normalized', ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'Color', 'red', 'FontSize', 11, ...
                'BackgroundColor', 'black');
            
            title(app.UIAxes_2, 'Stereo Error');
        end
        
        %% 4. SHOW IDENTITY ERROR (when images are identical)
        function showIdentityError(app, img1, img2)
            % Special error display when images are identical
            
            % Create display image
            if size(img1, 3) == 3
                img_display = img1;
            else
                img_display = cat(3, img1, img1, img1);
            end
            
            imshow(img_display, 'Parent', app.UIAxes_2);
            
            % Overlay big red warning
            hold(app.UIAxes_2, 'on');
            
            % Draw red X
            [h, w, ~] = size(img_display);
            plot(app.UIAxes_2, [1, w], [1, h], 'r-', 'LineWidth', 3);
            plot(app.UIAxes_2, [1, w], [h, 1], 'r-', 'LineWidth', 3);
            
            % Add warning text
            text(app.UIAxes_2, w/2, h/2 - 40, ...
                '⚠️ IDENTICAL IMAGES!', ...
                'Color', 'red', 'FontSize', 20, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', 'BackgroundColor', 'black');
            
            text(app.UIAxes_2, w/2, h/2, ...
                {'You are comparing THE SAME image twice.', ...
                 '', ...
                 'For Stereo Vision you need:', ...
                 '1. LEFT image of a scene', ...
                 '2. RIGHT image of the same scene'}, ...
                'Color', 'yellow', 'FontSize', 12, ...
                'HorizontalAlignment', 'center', 'BackgroundColor', 'black');
            
            text(app.UIAxes_2, w/2, h/2 + 80, ...
                {'SOLUTION:', ...
                 '1. Load a different second image', ...
                 '2. Use test stereo pair button', ...
                 '3. Take photos with camera shift'}, ...
                'Color', 'cyan', 'FontSize', 11, ...
                'HorizontalAlignment', 'center', 'BackgroundColor', 'black');
            
            hold(app.UIAxes_2, 'off');
            title(app.UIAxes_2, 'ERROR: Not a Stereo Pair');
        end
        
        %% 5. SHOW SIMPLE STEREO PAIR (basic side-by-side)
        function showSimpleStereoPair(app, I1, I2, points1, points2, indexPairs)
            % Show simple side-by-side view with matches
            
            stereoPair = [I1, I2];
            imshow(stereoPair, 'Parent', app.UIAxes_2);
            
            if ~isempty(indexPairs)
                xOffset = size(I1, 2);
                hold(app.UIAxes_2, 'on');
                
                % Show up to 20 matches
                numToShow = min(20, size(indexPairs, 1));
                for i = 1:numToShow
                    % Get points
                    pt1 = points1(indexPairs(i, 1)).Location;
                    pt2 = points2(indexPairs(i, 2)).Location;
                    
                    % Plot
                    plot(app.UIAxes_2, pt1(1), pt1(2), 'ro', 'MarkerSize', 6);
                    plot(app.UIAxes_2, pt2(1) + xOffset, pt2(2), 'bo', 'MarkerSize', 6);
                    plot(app.UIAxes_2, [pt1(1), pt2(1) + xOffset], [pt1(2), pt2(2)], ...
                        'g-', 'LineWidth', 1);
                end
                hold(app.UIAxes_2, 'off');
            end
        end
        
        %% 6. SHOW MATCHES ONLY (without epipolar lines)
        function showMatchesOnly(app, I1, I2, points1, points2)
            % Show matches without epipolar lines
            
            stereoPair = [I1, I2];
            imshow(stereoPair, 'Parent', app.UIAxes_2);
            hold(app.UIAxes_2, 'on');
            
            xOffset = size(I1, 2);
            
            % Plot points and connections (limit to 30 for clarity)
            numToShow = min(30, length(points1));
            for i = 1:numToShow
                % Plot point in first image
                plot(app.UIAxes_2, points1(i).Location(1), points1(i).Location(2), ...
                    'ro', 'MarkerSize', 6);
                
                % Plot point in second image (with offset)
                plot(app.UIAxes_2, points2(i).Location(1) + xOffset, ...
                    points2(i).Location(2), 'bo', 'MarkerSize', 6);
                
                % Draw connecting line
                plot(app.UIAxes_2, ...
                    [points1(i).Location(1), points2(i).Location(1) + xOffset], ...
                    [points1(i).Location(2), points2(i).Location(2)], ...
                    'g-', 'LineWidth', 0.5);
            end
            
            hold(app.UIAxes_2, 'off');
        end
        
        %% 7. IMAGE HASH FUNCTION (for debugging)
        function hash = getImageHash(~, img)
            % Create simple hash for image comparison
            % Returns: hash string based on image content
            
            if isempty(img)
                hash = 'EMPTY';
                return;
            end
            
            % Convert to double and compute simple hash
            if isa(img, 'uint8')
                img_double = double(img);
            else
                img_double = double(img);
            end
            
            % Create hash from image statistics
            hash_val = sum(img_double(:));
            hash = sprintf('HASH_%.4f', hash_val);
        end
        
        %% 8. CHECK IMAGE DIFFERENCE (percentage difference)
        function diffPercent = checkImageDifference(~, img1, img2)
            % Calculate percentage difference between two images
            % Returns: difference percentage (0-100)
            
            % Convert to grayscale double
            if size(img1, 3) == 3
                img1_gray = rgb2gray(im2double(img1));
            else
                img1_gray = im2double(img1);
            end
            
            if size(img2, 3) == 3
                img2_gray = rgb2gray(im2double(img2));
            else
                img2_gray = im2double(img2);
            end
            
            % Resize to same dimensions
            if ~isequal(size(img1_gray), size(img2_gray))
                min_h = min(size(img1_gray,1), size(img2_gray,1));
                min_w = min(size(img1_gray,2), size(img2_gray,2));
                img1_gray = imresize(img1_gray, [min_h, min_w]);
                img2_gray = imresize(img2_gray, [min_h, min_w]);
            end
            
            % Calculate absolute difference percentage
            diffPercent = mean(abs(img1_gray(:) - img2_gray(:))) * 100;
        end
        
        %% Show HOG error
        function showHOGError(app, image, errorMsg)
            imshow(image, 'Parent', app.UIAxes_2);
            
            hold(app.UIAxes_2, 'on');
            
            % Extract short error message
            if contains(errorMsg, ':')
                shortErr = extractAfter(errorMsg, ':');
                shortErr = strtrim(shortErr);
            else
                shortErr = errorMsg;
            end
            
            % Create error display
            [h, w] = size(image);
            
            % Dark overlay
            patch(app.UIAxes_2, [0, w, w, 0], [0, 0, h, h], ...
                [0, 0, 0], 'FaceAlpha', 0.6, 'EdgeColor', 'none');
            
            % Error icon
            text(app.UIAxes_2, w/2, h/2 - 40, '❌', ...
                'Color', 'red', 'FontSize', 40, ...
                'HorizontalAlignment', 'center');
            
            % Error title
            text(app.UIAxes_2, w/2, h/2, ...
                'HOG Processing Failed', ...
                'Color', [1, 0.3, 0.3], 'FontSize', 16, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center');
            
            % Error message
            text(app.UIAxes_2, w/2, h/2 + 30, ...
                shortErr, ...
                'Color', 'white', 'FontSize', 11, ...
                'HorizontalAlignment', 'center');
            
            % Suggestions
            text(app.UIAxes_2, w/2, h/2 + 80, ...
                {'Try:', ...
                 '• Reduce cell size', ...
                 '• Use larger image', ...
                 '• Check parameter ranges'}, ...
                'Color', 'cyan', 'FontSize', 10, ...
                'HorizontalAlignment', 'center');
            
            hold(app.UIAxes_2, 'off');
            
            title(app.UIAxes_2, 'HOG Error');
        end
        
        %% Enhanced HOG visualization with custom colors
        function enhancedHOG = createEnhancedHOGVisualization(I, features, visualization, cellSize)
            % Create enhanced visualization with better colors
            
            tempFig = figure('Visible', 'off', 'Position', [100, 100, 900, 400]);
            
            % Create subplot layout
            subplot(1, 2, 1);
            imshow(I);
            title('Original Image', 'FontSize', 12);
            
            subplot(1, 2, 2);
            imshow(I);
            hold on;
            
            % Enhanced visualization with gradient colors
            numFeatures = length(visualization);
            colors = jet(numFeatures);  % Color gradient
            
            for i = 1:min(100, numFeatures)  % Limit for performance
                plot(visualization(i), 'Color', colors(i,:), 'LineWidth', 1.5);
            end
            
            hold off;
            title(sprintf('HOG Features (Cell Size: %d)', cellSize), 'FontSize', 12);
            
            % Capture figure
            frame = getframe(gcf);
            enhancedHOG = frame.cdata;
            
            close(tempFig);
        end
        % RESTORED: Core image processing logic
        function J = ProcessImage(app)
            if isempty(app.ProcessedImage)
                cla(app.UIAxes_2);
                J = [];
                return;
            end
        
            % Base image (stacked result)
            I = im2double(app.ProcessedImage);
            J = I;
        
            % Always define grayscale safely
            if size(I,3) == 3
                gray = rgb2gray(I);
            else
                gray = I;
            end
        
            % Read sliders
            p1 = app.ParameterSlider.Value;
            p2 = app.ParameterSlider_2.Value;
            p3 = app.ParameterSlider_3.Value;
            L1 = app.ParameterEditFieldLabel;
            L2 = app.ParameterEditField_2Label;
            L3 = app.ParameterEditField_3Label;
        
            operation = app.OperationDropDown.Value;
            
            % APPLY SELECTED OPERATION
            switch operation
                %% 1. Image Enhancement
                case 'Image Enhancement (Gamma Correction)'
                    L1.Text = 'Gamma Value (0.1 to 5)';
                    J = I.^p1;
        
                case 'Image Enhancement (Histogram Equalization)'
                    L1.Text = 'N/A';
                    J = histeq(I); 
                case 'Image Enhancement (Brightness Adjustment)'
                    L1.Text = 'Brightness Factor (0.5 - 2)';
                    J = I * p1;
                    J = max(0, min(1, J));
        
                %% 2. Spatial-Domain Filtering
                case {'Spatial Smoothing (Box)', 'Spatial Smoothing (Weighted Average)', 'Spatial Sharpening (Laplacian)', 'Spatial Sharpening (Boosting)'}
                    K = round(p1);
                    if mod(K, 2) == 0, K = K + 1; end
                    K = max(3, K);
                    L1.Text = ['Kernel Size (Current: ' num2str(K) 'x' num2str(K) ')'];
                    
                    if size(I, 3) == 3
                        R = I(:,:,1); G = I(:,:,2); B = I(:,:,3);
                    else
                        R = I; G = I; B = I;
                    end
        
                    switch operation
                        case 'Spatial Smoothing (Box)'
                            h = ones(K) / K^2;
                            R = imfilter(R, h, 'replicate'); G = imfilter(G, h, 'replicate'); B = imfilter(B, h, 'replicate');
                            
                        case 'Spatial Smoothing (Weighted Average)'
                            h = fspecial('gaussian', K, (K-1)/6);
                            R = imfilter(R, h, 'replicate'); G = imfilter(G, h, 'replicate'); B = imfilter(B, h, 'replicate');
                            
                        case 'Spatial Sharpening (Laplacian)'
                            h = fspecial('laplacian', 0);
                            R_lap = imfilter(R, h, 'replicate'); G_lap = imfilter(G, h, 'replicate'); B_lap = imfilter(B, h, 'replicate');
                            R = R - R_lap; G = G - G_lap; B = B - B_lap;
                            
                        case 'Spatial Sharpening (Boosting)'
                            L1.Text = 'Boosting Factor (k)';
                            k = p1;
                            h_blur = fspecial('gaussian', K, 0.5); 
                            R_blur = imfilter(R, h_blur, 'replicate'); G_blur = imfilter(G, h_blur, 'replicate'); B_blur = imfilter(B, h_blur, 'replicate');
                            R_mask = R - R_blur; G_mask = G - G_blur; B_mask = B - B_blur;
                            R = R + k * R_mask; G = G + k * G_mask; B = B + k * B_mask;
                    end
                    J = cat(3, R, G, B);
        
                case 'Spatial Smoothing (Median)'
                    K = round(p1);
                    if mod(K, 2) == 0, K = K + 1; end
                    K = max(3, K);
                    L1.Text = ['Filter Size (Current: ' num2str(K) 'x' num2str(K) ')'];
                
                    I_double = im2double(I);
                
                    if size(I_double, 3) == 3
                        % Apply median filter to each color channel separately
                        R = medfilt2(I_double(:,:,1), [K K]);
                        G = medfilt2(I_double(:,:,2), [K K]);
                        B = medfilt2(I_double(:,:,3), [K K]);
                        J = cat(3, R, G, B);
                    else
                        % Grayscale image
                        J = medfilt2(I_double, [K K]);
                    end                    
               case 'Spatial Sharpening (Sobel Horizontal)'
                    L1.Text = 'N/A';
                    h = fspecial('sobel');
                    F = imfilter(I, h', 'replicate'); % edge map (horizontal)
                    J = I + 0.5 * F; % add edges back with small scaling
                
                case 'Spatial Sharpening (Sobel Vertical)'
                    L1.Text = 'N/A';
                    h = fspecial('sobel');
                    F = imfilter(I, h, 'replicate'); % edge map (vertical)
                    J = I + 0.5 * F;
        
                case 'Spatial Sharpening (Prewitt Horizontal)'
                    L1.Text = 'N/A';
                    h = [-1 -1 -1; 0 0 0; 1 1 1];
                    F = imfilter(I, h', 'replicate');
                    J = I + 0.5 * F;
                
                case 'Spatial Sharpening (Prewitt Vertical)'
                    L1.Text = 'N/A';
                    h = [-1 -1 -1; 0 0 0; 1 1 1];
                    F = imfilter(I, h, 'replicate');
                    J = I + 0.5 * F; 
                
                %% 3. Frequency-Domain Filtering
                case {'Frequency Smoothing (Ideal Low-pass)', 'Frequency Smoothing (Butterworth Low-pass)', 'Frequency Smoothing (Gaussian Low-pass)', ...
                      'Frequency Sharpening (Ideal High-pass)', 'Frequency Sharpening (Butterworth High-pass)', 'Frequency Sharpening (Gaussian High-pass)'}
                    
                    D0 = p1; 
                    L1.Text = ['Cutoff Freq D0 (Current: ' num2str(D0, 3) ')'];
                    
                    if size(I, 3) == 3
                        I_gray = rgb2gray(I);
                    else
                        I_gray = I;
                    end
        
                    [M, N] = size(I_gray);
                    F = fftshift(fft2(I_gray));
                    H = zeros(M, N);
                    
                    for u = 1:M
                        for v = 1:N
                            D = sqrt((u - M/2)^2 + (v - N/2)^2);
                            n = 2; 
                            sigma = D0;
                            
                            switch operation
                                case 'Frequency Smoothing (Ideal Low-pass)', if D <= D0, H(u, v) = 1; end
                                case 'Frequency Smoothing (Butterworth Low-pass)', H(u, v) = 1 / (1 + (D / D0)^(2 * n));
                                case 'Frequency Smoothing (Gaussian Low-pass)', H(u, v) = exp(-(D^2) / (2 * sigma^2));
                                case 'Frequency Sharpening (Ideal High-pass)', H(u, v) = 1 - (D <= D0);
                                case 'Frequency Sharpening (Butterworth High-pass)', H(u, v) = 1 - (1 / (1 + (D / D0)^(2 * n)));
                                case 'Frequency Sharpening (Gaussian High-pass)', H(u, v) = 1 - exp(-(D^2) / (2 * sigma^2));
                            end
                        end
                    end
                    
                    G_filtered = H .* F;
                    J = real(ifft2(ifftshift(G_filtered)));
        
                %% 4. Color Space conversion
                case 'Color Space (HSI)'
                    L1.Text = 'N/A';
                    if size(I, 3) == 3, J = rgb2hsv(I); title(app.UIAxes_2, 'Processed Image (HSV/HSI)'); else, J = I; end
                case 'Color Space (L*a*b*)'
                    L1.Text = 'N/A';
                    if size(I, 3) == 3, J = rgb2lab(I); title(app.UIAxes_2, 'Processed Image (L*a*b*)'); else, J = I; end
                case 'Color Space (YCbCr)'
                    L1.Text = 'N/A';
                    if size(I, 3) == 3, J = rgb2ycbcr(I); title(app.UIAxes_2, 'Processed Image (YCbCr)'); else, J = I; end
                
                %% 5. Gaussian Pyramid (Display Single Level)
                case 'Pyramids (Gaussian)'
                    level = round(p1); % The level to display (2 to 6)
                    % We need to generate one more level than requested (level+1) to ensure the 
                    % loop doesn't fail if the user selects the max level.
                    numLevels = level; 
                    L1.Text = ['Level (Current: ' num2str(level) ')'];

                    G = I; % G{1} is the original image (Level 1)
                    
                    % Loop to generate the requested level
                    for k = 2:level
                        G = imresize(G, 0.5); % Scale down to the next level
                    end
                    
                    J = G; % J is now the image at the requested 'level'
                
                    % Display the single level image
                    imshow(J, 'Parent', app.UIAxes_2);
                    title(app.UIAxes_2, ['Gaussian Pyramid - Level ' num2str(level)]);
                    return;

                %% 6. Laplacian Pyramid (Display Single Level)
                case 'Pyramids (Laplacian)'
                    level = round(p1); % The level to display (2 to 6)
                    L1.Text = ['Level (Current: ' num2str(level) ')'];

                    % The Laplacian pyramid is based on differences, so we need levels up to 
                    % 'level' and 'level + 1' for the difference calculation (if level < max).
                    
                    % 1. Create Gaussian levels needed for the calculation
                    numGaussianLevels = level + 1;
                    G = cell(1, numGaussianLevels);
                    G{1} = I;
                    for k = 2:numGaussianLevels
                        G{k} = imresize(G{k-1}, 0.5);
                    end
                
                    % 2. Calculate the required Laplacian level
                    if level < app.ParameterSlider.Limits(2) % If not the final level
                        % Level L is G_k - Up(G_{k+1})
                        
                        % Upsample G{level+1} to the size of G{level}
                        up = imresize(G{level+1}, size(G{level}(:,:,1))); 
                        
                        % Calculate difference
                        L = G{level} - up;
                        
                        J = L;
                        
                    elseif level == app.ParameterSlider.Limits(2) % If it is the final, smallest level
                        % The final Laplacian level is the smallest Gaussian level
                        J = G{level};
                    else
                         % Should not happen if limits are respected, fall back to level 1
                         J = I;
                    end
                
                    % Display the single level image
                    imshow(J, 'Parent', app.UIAxes_2);
                    title(app.UIAxes_2, ['Laplacian Pyramid - Level ' num2str(level)]);
                    return;

                %% 7. Template Matching (Uses User-Selected Template)
                case 'Template Matching'
                    % --- Check: Ensure a template has been selected ---
                    if isempty(app.TemplateImage)
                        J = I; 
                        imshow(J, 'Parent', app.UIAxes_2);
                        title(app.UIAxes_2, 'Template Matching (Error: Select a template first!)');
                        return;
                    end
                    
                    % 1. Get the Image and Template
                    gray = im2gray(I); 
                    template = im2gray(im2double(app.TemplateImage)); 

                    % 2. Perform Normalized 2-D Cross-Correlation
                    C = normxcorr2(template, gray);
                
                    % 3. Find the Peak Correlation Location and Threshold
                    
                    % Find the absolute maximum correlation value
                    max_corr = max(C(:));
                    
                    % Use the slider value (e.g., 0.85) as the threshold factor
                    threshold_factor = app.ParameterSlider.Value;
                    correlation_threshold = max_corr * threshold_factor; 
                    
                    % Create a logical map of all above-threshold points
                    C_thresh = (C >= correlation_threshold);
                    
                    % Use imregionalmax for Non-Maximum Suppression to find distinct peaks
                    % Set neighborhood to size of template-1 for better separation
                    template_h = size(template, 1);
                    template_w = size(template, 2);
                    
                    % Use 'imregionalmax' only on the thresholded correlation map
                    C_maxima = imregionalmax(C_thresh); 
                    
                    % Get coordinates of distinct local maxima
                    [y_peaks, x_peaks] = find(C_maxima);
                    
                    % 4. Display the Result
                    
                    % Initialize display
                    imshow(gray, 'Parent', app.UIAxes_2); 
                    hold(app.UIAxes_2, 'on');
                    
                    % Loop through all detected, distinct peaks
                    for k = 1:length(y_peaks)
                        y_peak = y_peaks(k);
                        x_peak = x_peaks(k);
                        
                        % Calculate the top-left corner of the match (offset)
                        y_offset = y_peak - template_h;
                        x_offset = x_peak - template_w;
                        
                        % Draw a bounding box
                        rectangle(app.UIAxes_2, 'Position', ...
                            [x_offset, y_offset, template_w, template_h], ...
                            'EdgeColor', 'r', 'LineWidth', 2);
                    end
                
                    hold(app.UIAxes_2, 'off');
                    title(app.UIAxes_2, sprintf('Template Matching: Found %d Matches (Threshold: %.2f)', length(y_peaks), threshold_factor));
                    return;                
                %% 8. Filter Banks (Gabor)
                case 'Filter Banks (Gabor)'
                    gray = im2gray(I);
                
                    lambda = 8; theta = 0; sigma = 2;
                    [X, Y] = meshgrid(-20:20, -20:20);
                
                    g = exp(-(X.^2 + Y.^2)/(2*sigma^2)) .* cos(2*pi*X/lambda);
                
                    J = imfilter(gray, g, 'replicate');
                %% 9. Edge detection
                    case 'Edge Detection (Sobel)'
                        J = edge(im2gray(I), 'sobel');
            
                    case 'Edge Detection (Canny)'
                        J = edge(im2gray(I), 'canny');
            
                    case 'Edge Detection (Prewitt)'
                        J = edge(im2gray(I), 'prewitt');
                %% 10. Corner Detection
                case 'Corner Detection (Harris)'
                      gray = im2gray(I);
                        
                      % Compute gradients
                      [Ix, Iy] = gradient(gray);
                       
                      % Compute products of gradients
                      Ix2 = imgaussfilt(Ix.^2, 1);
                      Iy2 = imgaussfilt(Iy.^2, 1);
                      Ixy = imgaussfilt(Ix.*Iy, 1);
                      
                      % Harris response
                      k = 0.04;
                      R = (Ix2 .* Iy2 - Ixy.^2) - k * (Ix2 + Iy2).^2;
                        
                      % Threshold
                      thresh = 0.01 * max(R(:));
                      corners = R > thresh;
                        
                      imshow(gray, 'Parent', app.UIAxes_2); hold(app.UIAxes_2,'on');
                      [y, x] = find(corners);
                      plot(app.UIAxes_2, x, y, 'r.');
                      hold(app.UIAxes_2,'off');
                      return;
                case 'Corner Detection (FAST)'
                      gray = im2uint8(im2gray(I));
                      corners = cornermetric(gray);
                        
                      thresh = max(corners(:)) * 0.2;
                      [y, x] = find(corners > thresh);
                        
                      imshow(gray, 'Parent', app.UIAxes_2); hold(app.UIAxes_2,'on');
                      plot(app.UIAxes_2, x, y, 'g.');
                      hold(app.UIAxes_2,'off');
                      return;

                %% 11. DoG (Difference of Gaussian)
                case 'DoG (Difference of Gaussian)'
                    sigma1 = p1;
                    sigma2 = p2;
                    
                    % Use the defined gray variable
                    grayImg = gray;
                    
                    G1 = imgaussfilt(grayImg, sigma1);
                    G2 = imgaussfilt(grayImg, sigma2);
                    
                    J = G1 - G2;
                    J = mat2gray(J); % Normalize to [0, 1]
                
                %% 12. LoG (Laplacian of Gaussian)
                case 'LoG (Laplacian of Gaussian)'
                    sigma = p1;
                    grayImg = gray;
                    
                    % Apply Gaussian smoothing first
                    smoothed = imgaussfilt(grayImg, sigma);
                    % Then apply Laplacian
                    laplacian = fspecial('laplacian', 0);
                    J = imfilter(smoothed, laplacian, 'replicate');
                    J = mat2gray(J);
                
                %% 13. HoG (Histogram of Oriented Gradients)
                case 'HoG (Histogram of Oriented Gradients)'
                       % --- Read parameters from sliders ---
                    cellSize  = round(app.ParameterSlider.Value);
                    blockSize = round(app.ParameterSlider_2.Value);
                    numBins   = round(app.ParameterSlider_3.Value);
                
                    % Safety clamps (VERY important for stability)
                    cellSize  = max(4, cellSize);
                    blockSize = max(1, blockSize);
                    numBins   = max(6, numBins);
                
                    % --- Convert to grayscale uint8 ---
                    if size(I,3) == 3
                        gray = rgb2gray(I);
                    else
                        gray = I;
                    end
                    gray = im2uint8(gray);
                
                    % --- Extract HOG ---
                    [~, hogVis] = extractHOGFeatures(gray, ...
                        'CellSize', [cellSize cellSize], ...
                        'BlockSize', [blockSize blockSize], ...
                        'NumBins', numBins);
                
                    % --- Render visualization to image (App Designer safe) ---
                    tempFig = figure('Visible','off');
                    imshow(gray);
                    hold on;
                    plot(hogVis);
                    hold off;
                
                    frame = getframe(gca);
                    J = frame.cdata;
                    close(tempFig);
                
                    % Display result
                    imshow(J, 'Parent', app.UIAxes_2);
                    title(app.UIAxes_2, sprintf( ...
                        'HoG | Cell=%d Block=%d Bins=%d', ...
                        cellSize, blockSize, numBins));
                
                    return;

    %% 14. Hough Transform for Circles
                case 'Hough Transform (Cirles)'
                    minR = round(p1);
                    maxR = round(p2);
                    sens = p3;
                    
                    grayImg = gray;
                    gray8 = im2uint8(grayImg);
                    
                    % Find circles using Hough transform
                    [centers, radii] = imfindcircles(gray8, [minR maxR], ...
                        'Sensitivity', sens, ...
                        'ObjectPolarity', 'bright');
                    
                    % Display results
                    imshow(grayImg, 'Parent', app.UIAxes_2);
                    hold(app.UIAxes_2, 'on');
                    
                    if ~isempty(centers)
                        viscircles(app.UIAxes_2, centers, radii, 'Color', 'r');
                        title(app.UIAxes_2, sprintf('Found %d circles', size(centers, 1)));
                    else
                        title(app.UIAxes_2, 'No circles found');
                    end
                    
                    hold(app.UIAxes_2, 'off');
                    return;
                
                %% 15. RANSAC Line Detection (Simplified version)
                case 'RANSAC (Line Detection)'
                    grayImg = gray;
                    
                    % First, detect edges
                    edgeImg = edge(grayImg, 'canny');
                    
                    % Get edge points
                    [y, x] = find(edgeImg);
                    points = [x, y];
                    
                    if size(points, 1) < 2
                        J = I;
                        title(app.UIAxes_2, 'Not enough edge points for RANSAC');
                        return;
                    end
                    
                    % Simple RANSAC for line fitting
                    maxIterations = 1000;
                    threshold = round(p1);
                    minInliers = p2 * size(points, 1); % Percentage of points
                    
                    bestLine = [];
                    bestInliers = [];
                    
                    for iter = 1:maxIterations
                        % Randomly select 2 points
                        idx = randperm(size(points, 1), 2);
                        p1_ransac = points(idx(1), :);
                        p2_ransac = points(idx(2), :);
                        
                        % Calculate line parameters (ax + by + c = 0)
                        a = p2_ransac(2) - p1_ransac(2);
                        b = p1_ransac(1) - p2_ransac(1);
                        c = p2_ransac(1)*p1_ransac(2) - p1_ransac(1)*p2_ransac(2);
                        
                        % Calculate distances
                        denom = sqrt(a^2 + b^2);
                        if denom > 0
                            distances = abs(a*points(:,1) + b*points(:,2) + c) / denom;
                            inliers = distances < threshold;
                            
                            if sum(inliers) > length(bestInliers)
                                bestInliers = inliers;
                                % Refit line using all inliers
                                if sum(inliers) >= 2
                                    inlierPoints = points(inliers, :);
                                    % Use polyfit for better line estimation
                                    coeff = polyfit(inlierPoints(:,1), inlierPoints(:,2), 1);
                                    bestLine = coeff;
                                end
                            end
                        end
                    end
                    
                    % Display results
                    imshow(I, 'Parent', app.UIAxes_2);
                    hold(app.UIAxes_2, 'on');
                    
                    if ~isempty(bestLine) && sum(bestInliers) >= minInliers
                        % Plot inliers
                        inlierPoints = points(bestInliers, :);
                        plot(app.UIAxes_2, inlierPoints(:,1), inlierPoints(:,2), 'r.', 'MarkerSize', 10);
                        
                        % Plot fitted line
                        xlims = xlim(app.UIAxes_2);
                        y_fit = polyval(bestLine, xlims);
                        plot(app.UIAxes_2, xlims, y_fit, 'g-', 'LineWidth', 2);
                        
                        title(app.UIAxes_2, sprintf('RANSAC Line: %d inliers', sum(bestInliers)));
                    else
                        title(app.UIAxes_2, 'No line found with sufficient inliers');
                    end
                    
                    hold(app.UIAxes_2, 'off');
                    return;
                
                %% 16. RANSAC Circle Detection (Simplified)
                case 'RANSAC (Circle Detection)'
                    grayImg = gray;
                    gray8 = im2uint8(grayImg);
                    
                    minR = round(p1);
                    maxR = round(p2);
                    
                    % Use imfindcircles which internally uses Hough transform
                    [centers, radii] = imfindcircles(gray8, [minR maxR], ...
                        'Sensitivity', 0.9);
                    
                    imshow(I, 'Parent', app.UIAxes_2);
                    hold(app.UIAxes_2, 'on');
                    
                    if ~isempty(centers)
                        viscircles(app.UIAxes_2, centers, radii, 'Color', 'r');
                        title(app.UIAxes_2, sprintf('Found %d circles', size(centers, 1)));
                    else
                        title(app.UIAxes_2, 'No circles found');
                    end
                    
                    hold(app.UIAxes_2, 'off');
                    return;
                
                %% 17. Stereo Vision (Epipolar Line) - Simplified
                case 'Stereo Vision (Epipolar Line)'
                    % --- CHECK INPUTS ---
                    if isempty(app.OriginalImage) || isempty(app.SecondImage)
                        uialert(app.UIFigure, ...
                            'Please load BOTH images (left & right) first.', ...
                            'Missing Images');
                        return;
                    end
                
                    % --- USE ORIGINAL IMAGES ---
                    leftImage  = app.OriginalImage;
                    rightImage = app.SecondImage;
                
                    % Convert to grayscale
                    I1 = im2gray(leftImage);
                    I2 = im2gray(rightImage);
                
                    % --- FEATURE DETECTION ---
                    points1 = detectSURFFeatures(I1);
                    points2 = detectSURFFeatures(I2);
                
                    % --- FEATURE EXTRACTION ---
                    [features1, validPoints1] = extractFeatures(I1, points1);
                    [features2, validPoints2] = extractFeatures(I2, points2);
                
                    % --- FEATURE MATCHING ---
                    indexPairs = matchFeatures(features1, features2, 'Unique', true);
                    matchedPoints1 = validPoints1(indexPairs(:,1));
                    matchedPoints2 = validPoints2(indexPairs(:,2));
                
                    if matchedPoints1.Count < 8
                        uialert(app.UIFigure, ...
                            'Not enough matches to estimate the Fundamental Matrix.', ...
                            'Stereo Error');
                        return;
                    end
                
                    % --- FUNDAMENTAL MATRIX (RANSAC) ---
                    [F, inliers] = estimateFundamentalMatrix( ...
                        matchedPoints1, matchedPoints2, ...
                        'Method', 'RANSAC', ...
                        'NumTrials', 2000, ...
                        'DistanceThreshold', 1);
                
                    % Keep only inliers
                    inlierPoints1 = matchedPoints1(inliers);
                    inlierPoints2 = matchedPoints2(inliers);
                
                    % --- LIMIT NUMBER OF LINES (slider-controlled) ---
                    maxLines = round(app.ParameterSlider.Value);
                    maxLines = max(1, min(maxLines, inlierPoints1.Count));
                
                    inlierPoints1 = inlierPoints1(1:maxLines);
                    inlierPoints2 = inlierPoints2(1:maxLines);
                
                    % --- DISPLAY LEFT IMAGE ---
                    imshow(leftImage, 'Parent', app.UIAxes);
                    hold(app.UIAxes, 'on');
                    plot(app.UIAxes, ...
                        inlierPoints1.Location(:,1), ...
                        inlierPoints1.Location(:,2), ...
                        'go', 'LineWidth', 1.5);
                
                    % Epipolar lines in LEFT image
                    epiLines1 = epipolarLine(F', inlierPoints2.Location);
                    borderPts1 = lineToBorderPoints(epiLines1, size(I1));
                
                    for k = 1:maxLines
                        line(app.UIAxes, ...
                            borderPts1(k,[1 3]), ...
                            borderPts1(k,[2 4]), ...
                            'Color','r','LineWidth',1.2);
                    end
                    hold(app.UIAxes, 'off');
                    title(app.UIAxes, 'Left Image + Epipolar Lines');
                
                    % --- DISPLAY RIGHT IMAGE ---
                    imshow(rightImage, 'Parent', app.UIAxes_2);
                    hold(app.UIAxes_2, 'on');
                    plot(app.UIAxes_2, ...
                        inlierPoints2.Location(:,1), ...
                        inlierPoints2.Location(:,2), ...
                        'go', 'LineWidth', 1.5);
                
                    % Epipolar lines in RIGHT image
                    epiLines2 = epipolarLine(F, inlierPoints1.Location);
                    borderPts2 = lineToBorderPoints(epiLines2, size(I2));
                
                    for k = 1:maxLines
                        line(app.UIAxes_2, ...
                            borderPts2(k,[1 3]), ...
                            borderPts2(k,[2 4]), ...
                            'Color','r','LineWidth',1.2);
                    end
                    hold(app.UIAxes_2, 'off');
                    title(app.UIAxes_2, 'Right Image + Epipolar Lines');
                
                    return;
                otherwise
                    J = I;
                end
           % PREVIEW ONLY — do NOT overwrite ProcessedImage
            imshow(J, 'Parent', app.UIAxes_2);
            switch operation
            case 'Image Enhancement (Gamma Correction)'
                 title(app.UIAxes_2, 'Gamma Corrected Image');
            case 'Image Enhancement (Histogram Equalization)'
                title(app.UIAxes_2, 'Histogram Equalized Image');
            otherwise
                title(app.UIAxes_2, ['Processed Image (' operation ')']);
            end
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Populate dropdown
            app.OperationDropDown.Items = app.OperationList;
            app.OperationDropDown.Value = app.OperationList{1};

            % Default slider
            app.ParameterSlider.Limits = [0.1 5];
            app.ParameterSlider.Value = 1.0;
            app.ParameterEditField.Value = app.ParameterSlider.Value;
            app.ParameterEditFieldLabel.Text = 'Parameter';

            % Initialize SecondImage as empty
            app.SecondImage = [];

            % Default Template Selection
            app.SelectTemplateButton.Visible = 'off';

            % Try load default sample if available
            if exist('peppers.png','file')
                img = im2double(imread('peppers.png'));
                app.OriginalImage = img;
                app.ProcessedImage = img;
                imshow(app.OriginalImage, 'Parent', app.UIAxes);
                title(app.UIAxes, 'Original Image');
                imshow(app.ProcessedImage, 'Parent', app.UIAxes_2);
                title(app.UIAxes_2, 'Processed Image');
            else
                cla(app.UIAxes); title(app.UIAxes,'Original Image (Load Required)');
                cla(app.UIAxes_2); title(app.UIAxes_2,'Processed Image (Load Required)');
            end

            % Initial process (if an image exists)
            if ~isempty(app.OriginalImage)
                ProcessImage(app);
            end
        end

        % Value changed function: OperationDropDown
        function OperationDropDownValueChanged(app, event)
            L1 = app.ParameterEditFieldLabel;
            L2 = app.ParameterEditField_2Label;
            L3 = app.ParameterEditField_3Label;
            operation = app.OperationDropDown.Value;
            
            % Setup Defaults - show all controls initially
            app.ParameterSlider.Visible = true; 
            app.ParameterSlider_2.Visible = true; 
            app.ParameterSlider_3.Visible = true;
            app.ParameterEditField.Visible = true; 
            app.ParameterEditField_2.Visible = true; 
            app.ParameterEditField_3.Visible = true;
            L1.Visible = true; 
            L2.Visible = true; 
            L3.Visible = true;
            app.SelectTemplateButton.Visible = 'off';
            
            % Hide Load Second Image button by default, show only for Stereo
            app.LoadSecondImageButton.Visible = 'off';
        
            if strcmp(operation, 'Template Matching') 
                % Hide sliders 2 and 3
                app.ParameterSlider_2.Visible = false;
                app.ParameterSlider_3.Visible = false;
                app.ParameterEditField_2.Visible = false;
                app.ParameterEditField_3.Visible = false;
                L2.Visible = false;
                L3.Visible = false;
                
                app.ParameterSlider.Limits = [0.5 1.0]; 
                app.ParameterSlider.Value = 0.85;
                L1.Text = 'Corr. Threshold (0.5 to 1.0)';
                app.SelectTemplateButton.Visible = 'on';
                
            elseif contains(operation, 'DoG')
                % Show all 3 sliders for DoG
                L1.Text = 'Sigma 1'; 
                L2.Text = 'Sigma 2'; 
                L3.Text = 'N/A (Not Used)';
                L3.Visible = true;
                app.ParameterSlider_3.Visible = false; % Hide slider 3 but keep label
                app.ParameterEditField_3.Visible = false;
                
                app.ParameterSlider.Limits = [0.5 5]; 
                app.ParameterSlider_2.Limits = [1 8];
                app.ParameterSlider.Value = 1; 
                app.ParameterSlider_2.Value = 1.6;
                
            elseif contains(operation, 'LoG')
                % Only need sigma parameter
                app.ParameterSlider_2.Visible = false;
                app.ParameterSlider_3.Visible = false;
                app.ParameterEditField_2.Visible = false;
                app.ParameterEditField_3.Visible = false;
                L2.Visible = false;
                L3.Visible = false;
                
                L1.Text = 'Sigma'; 
                app.ParameterSlider.Limits = [0.5 5]; 
                app.ParameterSlider.Value = 1;
                
            elseif contains(operation, 'HoG')
                % Configure all three sliders for HOG
                app.ParameterSlider.Visible = true;
                app.ParameterSlider_2.Visible = true;
                app.ParameterSlider_3.Visible = true;
                app.ParameterEditField.Visible = true;
                app.ParameterEditField_2.Visible = true;
                app.ParameterEditField_3.Visible = true;
                
                % Set labels
                app.ParameterEditFieldLabel.Text = 'Cell Size (1-50)';
                app.ParameterEditField_2Label.Text = 'Block Size (1-50)';
                app.ParameterEditField_3Label.Text = 'Num Bins (1-50)';
                app.ParameterEditFieldLabel.Visible = true;
                app.ParameterEditField_2Label.Visible = true;
                app.ParameterEditField_3Label.Visible = true;
                
                % Set limits and default values
                app.ParameterSlider.Limits = [1 50];
                app.ParameterSlider.Value = 1;
                app.ParameterSlider_2.Limits = [1 50];
                app.ParameterSlider_2.Value = 1;
                app.ParameterSlider_3.Limits = [1 50];
                app.ParameterSlider_3.Value = 1;
                
                % Update display values
                app.ParameterEditField.Value = app.ParameterSlider.Value;
                app.ParameterEditField_2.Value = app.ParameterSlider_2.Value;
                app.ParameterEditField_3.Value = app.ParameterSlider_3.Value;
                
                % Hide unnecessary buttons
                app.SelectTemplateButton.Visible = 'off';
                app.LoadSecondImageButton.Visible = 'off';   

            elseif contains(operation, 'Hough')
                % Hough circle detection needs minR, maxR, sensitivity
                L1.Text = 'Min Radius'; 
                L2.Text = 'Max Radius'; 
                L3.Text = 'Sensitivity';
                
                app.ParameterSlider.Limits = [10 50]; 
                app.ParameterSlider_2.Limits = [30 120]; 
                app.ParameterSlider_3.Limits = [0.8 1];
                app.ParameterSlider.Value = 20; 
                app.ParameterSlider_2.Value = 60; 
                app.ParameterSlider_3.Value = 0.9;
                
            elseif contains(operation, 'RANSAC (Line Detection)')
                L1.Text = 'Distance Threshold'; 
                L2.Text = 'Min Inlier Ratio'; 
                L3.Text = 'N/A';
                app.ParameterSlider_3.Visible = false;
                app.ParameterEditField_3.Visible = false;
                
                app.ParameterSlider.Limits = [1 20]; 
                app.ParameterSlider_2.Limits = [0.1 0.5];
                app.ParameterSlider.Value = 5; 
                app.ParameterSlider_2.Value = 0.3;
                
            elseif contains(operation, 'RANSAC (Circle Detection)')
                L1.Text = 'Min Radius'; 
                L2.Text = 'Max Radius'; 
                L3.Text = 'N/A';
                app.ParameterSlider_3.Visible = false;
                app.ParameterEditField_3.Visible = false;
                
                app.ParameterSlider.Limits = [10 50]; 
                app.ParameterSlider_2.Limits = [30 120];
                app.ParameterSlider.Value = 20; 
                app.ParameterSlider_2.Value = 60;
                
            elseif contains(operation, 'Stereo Vision')
                % Show only first slider for line limit
                app.ParameterSlider.Visible = true;
                app.ParameterSlider_2.Visible = false;
                app.ParameterSlider_3.Visible = false;
                app.ParameterEditField.Visible = true;
                app.ParameterEditField_2.Visible = false;
                app.ParameterEditField_3.Visible = false;
                app.ParameterEditFieldLabel.Visible = true;
                app.ParameterEditField_2Label.Visible = false;
                app.ParameterEditField_3Label.Visible = false;
                
                % Set for line limit control
                app.ParameterEditFieldLabel.Text = 'Max Lines to Show (1-50)';
                app.ParameterSlider.Limits = [1 50];
                app.ParameterSlider.Value = 20;
                app.ParameterEditField.Value = app.ParameterSlider.Value;
                
                % Show Load Second Image button
                app.LoadSecondImageButton.Visible = 'on';
                            
            else
                % For other operations, hide sliders 2 and 3
                app.ParameterSlider_2.Visible = false;
                app.ParameterSlider_3.Visible = false;
                app.ParameterEditField_2.Visible = false;
                app.ParameterEditField_3.Visible = false;
                L2.Visible = false;
                L3.Visible = false;
                
                % Set appropriate limits for the first slider
                if contains(operation, 'Enhancement (Gamma)')
                    app.ParameterSlider.Limits = [0.1 5]; 
                    app.ParameterSlider.Value = 1.0;
                    L1.Text = 'Gamma Value (0.1 to 5)';
                elseif contains(operation, 'Spatial Smoothing') || contains(operation, 'Laplacian')
                    app.ParameterSlider.Limits = [3 11]; 
                    app.ParameterSlider.Value = 3;
                    L1.Text = 'Kernel Size (3 to 11)';
                elseif contains(operation, 'Sharpening (Boosting)')
                    app.ParameterSlider.Limits = [1 5]; 
                    app.ParameterSlider.Value = 1.0;
                    L1.Text = 'Boosting Factor (k)';
                elseif contains(operation, 'Frequency')
                    app.ParameterSlider.Limits = [1 100]; 
                    app.ParameterSlider.Value = 10; 
                    L1.Text = 'Cutoff Freq D0 (1 to 100)';
                elseif contains(operation, 'Pyramids')
                    app.ParameterSlider.Limits = [2 6]; 
                    app.ParameterSlider.Value = 4;
                    L1.Text = 'Level (2 to 6)';
                else
                    % Hide all controls for operations that don't need parameters
                    app.ParameterSlider.Visible = false;
                    app.ParameterEditField.Visible = false;
                    L1.Visible = false;
                end
            end
            
            % Update edit field values
            app.ParameterEditField.Value = app.ParameterSlider.Value;
            app.ParameterEditField_2.Value = app.ParameterSlider_2.Value;
            app.ParameterEditField_3.Value = app.ParameterSlider_3.Value;
            
            % Process the image
            ProcessImage(app);

        end

        % Value changed function: ParameterSlider
        function ParameterSliderValueChanged(app, event)
            % Update the numeric field display
            app.ParameterEditField.Value = app.ParameterSlider.Value;
            
            % Re-process the image with the new parameter
            ProcessImage(app);
        end

        % Button pushed function: LoadImageButton
        function LoadImageButtonPushed(app, event)
            [filename, pathname] = uigetfile({'*.png;*.jpg;*.tif','Image Files (*.png,*.jpg,*.tif)'}, ...
                'Select FIRST Image (Left View)');
            
            if filename ~= 0
                fprintf('\n=== Loading FIRST Image ===\n');
                fprintf('Selected file: %s\n', filename);
                
                fullPath = fullfile(pathname, filename);
                img = imread(fullPath);
                
                % Convert format (your existing code)
                if islogical(img)
                    img = uint8(img) * 255;
                elseif isa(img, 'double') || isa(img, 'single')
                    img = uint8(round(img * 255));
                elseif ~isa(img, 'uint8')
                    img = uint8(round(double(img) / max(img(:)) * 255));
                else
                    img = img;
                end
                
                % Store as FIRST image
                app.OriginalImage = img;     % First image
                app.ProcessedImage = img;    % Also store here for processing
                
                fprintf('Stored as OriginalImage: %dx%dx%d\n', ...
                    size(app.OriginalImage,1), size(app.OriginalImage,2), size(app.OriginalImage,3));
                
                % Display first image
                imshow(app.OriginalImage, 'Parent', app.UIAxes);
                title(app.UIAxes, sprintf('First Image: %s', filename));
                
                % Add text overlay
                text(app.UIAxes, 10, 30, ...
                    'FIRST IMAGE LOADED (Left View)', ...
                    'Color', 'green', 'FontSize', 12, 'FontWeight', 'bold', ...
                    'BackgroundColor', 'black');
                
                fprintf('=== First image loading complete ===\n\n');
            end
        end

        % Button pushed function: ResetButton
        function ResetButtonPushed(app, event)
            % Completely clear the stack
            app.ProcessedImage = app.OriginalImage;
            imshow(app.ProcessedImage, 'Parent', app.UIAxes_2);
            title(app.UIAxes_2, 'Reset to Original (Stack Cleared)');
        end

        % Button pushed function: SelectTemplateButton
        function SelectTemplateButtonPushed(app, event)
            if isempty(app.OriginalImage)
                uialert(app.UIFigure, 'Please load an image first.', 'Error', 'Icon', 'error');
                return;
            end
            
            % Ensure the Original Image is displayed for selection
            imshow(app.OriginalImage, 'Parent', app.UIAxes);
            title(app.UIAxes, 'Select Template Region');
            
            % Get the image data
            I = app.OriginalImage;
            
            % Use imrect to let the user draw a rectangle
            h = imrect(app.UIAxes); 
            
            % Wait for the user to confirm the selection (e.g., by double-clicking or pressing Enter)
            % This call pauses the execution until the rectangle is finalized.
            position = wait(h);
            
            % Delete the selection object
            delete(h);
            
            if ~isempty(position)
                % position is [x, y, width, height]
                x = round(position(1));
                y = round(position(2));
                w = round(position(3));
                h = round(position(4));
                
                % Handle bounds: ensure the crop doesn't go outside the image limits
                [M, N, ~] = size(I);
                
                x_end = min(x + w - 1, N);
                y_end = min(y + h - 1, M);
                x_start = max(1, x);
                y_start = max(1, y);

                % Crop the template from the original image
                app.TemplateImage = I(y_start:y_end, x_start:x_end, :);
                
                uialert(app.UIFigure, 'Template selected successfully! Now choose "Template Matching" from the Operation dropdown.', 'Success', 'Icon', 'success');

                % Optional: Display the selected template in a small separate axes or log its size
                title(app.UIAxes, 'Original Image'); % Restore title
            else
                title(app.UIAxes, 'Original Image'); % Restore title if selection was cancelled
            end
        end

        % Button pushed function: AddFilterButton
        function AddFilterButtonPushed(app, event)
            % Get the current processed result
            operation = app.OperationDropDown.Value;
            
            % For operations that display their own results (like HOG, Hough, etc.)
            % we need to handle them differently
            earlyReturnOperations = {
                'HoG (Histogram of Oriented Gradients)',
                'Hough Transform (Cirles)',
                'RANSAC (Line Detection)',
                'RANSAC (Circle Detection)',
                'Stereo Vision (Epipolar Line)'
            };
            
            if any(strcmp(operation, earlyReturnOperations))
                uialert(app.UIFigure, ...
                    'This operation displays results directly and cannot be added to the filter stack.', ...
                    'Information', 'Icon', 'info');
                return;
            end
            
            % For other operations, get the processed result
            tempResult = ProcessImage(app);
            if ~isempty(tempResult)
                % COMMIT: Save the result to the permanent stack property
                app.ProcessedImage = im2uint8(tempResult);
                
                % Update display
                imshow(app.ProcessedImage, 'Parent', app.UIAxes_2);
                title(app.UIAxes_2, 'FILTER ADDED TO STACK');
            end
        end

        % Value changed function: ParameterSlider_2
        function ParameterSlider_2ValueChanged(app, event)
            app.ParameterEditField_2.Value = app.ParameterSlider_2.Value;
            ProcessImage(app);        
        end

        % Value changed function: ParameterSlider_3
        function ParameterSlider_3ValueChanged(app, event)
            app.ParameterEditField_3.Value = app.ParameterSlider_3.Value;
            ProcessImage(app);
        end

        % Button pushed function: LoadSecondImageButton
        function LoadSecondImageButtonPushed(app, event)
            [file, path] = uigetfile({'*.jpg;*.png;*.bmp;*.tif;*.jpeg', 'Image Files'}, ...
                'Select SECOND Image (Right View)');
            
            if isequal(file, 0)
                fprintf('User cancelled second image selection\n');
                return;
            end
            
            fprintf('\n=== Loading SECOND Image ===\n');
            fprintf('Selected file: %s\n', file);
            
            % --- DEBUG: Show current state ---
            fprintf('BEFORE loading:\n');
            if ~isempty(app.OriginalImage)
                fprintf('  OriginalImage (1st): %dx%dx%d\n', ...
                    size(app.OriginalImage,1), size(app.OriginalImage,2), size(app.OriginalImage,3));
            else
                fprintf('  OriginalImage: EMPTY\n');
            end
            
            if ~isempty(app.SecondImage)
                fprintf('  SecondImage (2nd): %dx%dx%d\n', ...
                    size(app.SecondImage,1), size(app.SecondImage,2), size(app.SecondImage,3));
            else
                fprintf('  SecondImage: EMPTY\n');
            end
            
            % --- Read and process image ---
            fullPath = fullfile(path, file);
            img = imread(fullPath);
            
            % Convert to consistent format
            if islogical(img)
                img = uint8(img) * 255;
            elseif isa(img, 'double') || isa(img, 'single')
                if max(img(:)) <= 1
                    img = uint8(img * 255);
                else
                    img = uint8(img);
                end
            elseif ~isa(img, 'uint8')
                img = uint8(round(double(img) / double(max(img(:))) * 255));
            end
            
            % --- CRITICAL FIX: Store in SECONDIMAGE, not OriginalImage ---
            app.SecondImage = img;  % THIS IS THE FIX!
            
            fprintf('AFTER loading:\n');
            fprintf('  Stored as SecondImage: %dx%dx%d\n', ...
                size(app.SecondImage,1), size(app.SecondImage,2), size(app.SecondImage,3));
            
            % --- Display confirmation ---
            % Show second image in the ORIGINAL axes temporarily
            imshow(app.SecondImage, 'Parent', app.UIAxes);
            
            % Add text overlay to clarify
            text(app.UIAxes, 10, 30, ...
                'SECOND IMAGE LOADED (Right View)', ...
                'Color', 'yellow', 'FontSize', 12, 'FontWeight', 'bold', ...
                'BackgroundColor', 'black');
            
            title(app.UIAxes, sprintf('Second Image: %s', file));
            
            % Show success message
            uialert(app.UIFigure, ...
                sprintf('Second image loaded successfully!\n\nNow select "Stereo Vision (Epipolar Line)" from operations.'), ...
                'Success', 'Icon', 'success');
            
            fprintf('=== Second image loading complete ===\n\n');
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1345 728];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Original Image')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [51 355 555 358];

            % Create UIAxes_2
            app.UIAxes_2 = uiaxes(app.UIFigure);
            title(app.UIAxes_2, 'Processed Image')
            xlabel(app.UIAxes_2, 'X')
            ylabel(app.UIAxes_2, 'Y')
            zlabel(app.UIAxes_2, 'Z')
            app.UIAxes_2.Position = [695 354 604 358];

            % Create LoadImageButton
            app.LoadImageButton = uibutton(app.UIFigure, 'push');
            app.LoadImageButton.ButtonPushedFcn = createCallbackFcn(app, @LoadImageButtonPushed, true);
            app.LoadImageButton.Position = [178 278 130 46];
            app.LoadImageButton.Text = 'Load Image';

            % Create OperationLabel
            app.OperationLabel = uilabel(app.UIFigure);
            app.OperationLabel.HorizontalAlignment = 'right';
            app.OperationLabel.Position = [809 290 58 22];
            app.OperationLabel.Text = 'Operation';

            % Create OperationDropDown
            app.OperationDropDown = uidropdown(app.UIFigure);
            app.OperationDropDown.ValueChangedFcn = createCallbackFcn(app, @OperationDropDownValueChanged, true);
            app.OperationDropDown.Position = [882 290 100 22];

            % Create ParameterSliderLabel
            app.ParameterSliderLabel = uilabel(app.UIFigure);
            app.ParameterSliderLabel.HorizontalAlignment = 'right';
            app.ParameterSliderLabel.Position = [812 229 61 22];
            app.ParameterSliderLabel.Text = 'Parameter';

            % Create ParameterSlider
            app.ParameterSlider = uislider(app.UIFigure);
            app.ParameterSlider.ValueChangedFcn = createCallbackFcn(app, @ParameterSliderValueChanged, true);
            app.ParameterSlider.Position = [895 238 150 3];

            % Create ParameterEditFieldLabel
            app.ParameterEditFieldLabel = uilabel(app.UIFigure);
            app.ParameterEditFieldLabel.HorizontalAlignment = 'right';
            app.ParameterEditFieldLabel.Position = [812 152 170 22];
            app.ParameterEditFieldLabel.Text = 'Parameter';

            % Create ParameterEditField
            app.ParameterEditField = uieditfield(app.UIFigure, 'numeric');
            app.ParameterEditField.Position = [995 152 55 22];

            % Create ResetButton
            app.ResetButton = uibutton(app.UIFigure, 'push');
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
            app.ResetButton.Position = [411 278 130 46];
            app.ResetButton.Text = 'Reset';

            % Create SelectTemplateButton
            app.SelectTemplateButton = uibutton(app.UIFigure, 'push');
            app.SelectTemplateButton.ButtonPushedFcn = createCallbackFcn(app, @SelectTemplateButtonPushed, true);
            app.SelectTemplateButton.Position = [995 275 152 49];
            app.SelectTemplateButton.Text = 'Select Template';

            % Create AddFilterButton
            app.AddFilterButton = uibutton(app.UIFigure, 'push');
            app.AddFilterButton.ButtonPushedFcn = createCallbackFcn(app, @AddFilterButtonPushed, true);
            app.AddFilterButton.Position = [1162 276 153 45];
            app.AddFilterButton.Text = 'Add Filter';

            % Create ParameterSlider_2Label
            app.ParameterSlider_2Label = uilabel(app.UIFigure);
            app.ParameterSlider_2Label.HorizontalAlignment = 'right';
            app.ParameterSlider_2Label.Position = [1085 229 61 22];
            app.ParameterSlider_2Label.Text = 'Parameter';

            % Create ParameterSlider_2
            app.ParameterSlider_2 = uislider(app.UIFigure);
            app.ParameterSlider_2.ValueChangedFcn = createCallbackFcn(app, @ParameterSlider_2ValueChanged, true);
            app.ParameterSlider_2.Position = [1168 238 150 3];

            % Create ParameterEditField_2Label
            app.ParameterEditField_2Label = uilabel(app.UIFigure);
            app.ParameterEditField_2Label.HorizontalAlignment = 'right';
            app.ParameterEditField_2Label.Position = [1085 152 170 22];
            app.ParameterEditField_2Label.Text = 'Parameter';

            % Create ParameterEditField_2
            app.ParameterEditField_2 = uieditfield(app.UIFigure, 'numeric');
            app.ParameterEditField_2.Position = [1268 152 55 22];

            % Create LoadSecondImageButton
            app.LoadSecondImageButton = uibutton(app.UIFigure, 'push');
            app.LoadSecondImageButton.ButtonPushedFcn = createCallbackFcn(app, @LoadSecondImageButtonPushed, true);
            app.LoadSecondImageButton.Position = [996 276 152 45];
            app.LoadSecondImageButton.Text = 'Load Second Image';

            % Create ParameterSlider_3Label
            app.ParameterSlider_3Label = uilabel(app.UIFigure);
            app.ParameterSlider_3Label.HorizontalAlignment = 'right';
            app.ParameterSlider_3Label.Position = [812 101 61 22];
            app.ParameterSlider_3Label.Text = 'Parameter';

            % Create ParameterSlider_3
            app.ParameterSlider_3 = uislider(app.UIFigure);
            app.ParameterSlider_3.ValueChangedFcn = createCallbackFcn(app, @ParameterSlider_3ValueChanged, true);
            app.ParameterSlider_3.Position = [895 110 150 3];

            % Create ParameterEditField_3Label
            app.ParameterEditField_3Label = uilabel(app.UIFigure);
            app.ParameterEditField_3Label.HorizontalAlignment = 'right';
            app.ParameterEditField_3Label.Position = [812 24 170 22];
            app.ParameterEditField_3Label.Text = 'Parameter';

            % Create ParameterEditField_3
            app.ParameterEditField_3 = uieditfield(app.UIFigure, 'numeric');
            app.ParameterEditField_3.Position = [995 24 55 22];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Task3_2220165_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end