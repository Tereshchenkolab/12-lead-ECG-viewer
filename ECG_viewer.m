function ECG_viewer()
    warning('off')
    close all
    
    %% ECG Viewer for phyisians
    % Written by Annabel Li-Pershing in Tereshchenko Lab at OHSU
    % annabel2@pdx.edu;lipershi@ohsu.edu
    
    %% setup labels
    ECG_labels={'I','aVR','V1','V4','II','aVL','V2','V5','III','aVF','V3','V6','V1','II'};
    % GE report format lead order:
    % GE_lead= {'I','II','v1','v2','v3','v4','v5','v6','III','avR','avL','avF'};
    
    %% resolve screen resolution
    % get pixel count
    set(0,'units','pixels')
    pix = get(0,'screensize');
    % get screen size
    set(0,'unit','inches')
    inch= get(0,'screensize');
    res= pix/inch;
    if res == 96
        fontsize = 10;
        label_size = 10;
    elseif res < 96
        fontsize = 8;
        label_size = 10;
    else 
        fontsize = 10;
        label_size = 12;
    end
    
    %% setup variables
    graph_var = struct();
    graph_var.file_id = '';
    
    %% Graphic positioning 
    %(left corner x, left corner y, width, height) at normalize position
    % Plot position
    main_ECG_pos = [0.16,0.41,0.82,0.58];
    scroll_ECG_pos = [0.16,0.09,0.45,0.29];
    scroll_pos = [0.16,0.02,0.45,0.02];
    %  Left Panel Items
    getfile_pos = [0.02,0.7,.12,0.05];
    getfiletxt_pos = [0.02,0.65,0.12,0.03];
    plot_scale_pos = [0.02,0.5,0.12,0.08];
    plot_10sec_btn_pos = [0.02,0.58,0.12,0.05];
    fs_txt_pos = [0.02,0.90,0.08,0.05];
    fs_pos= [0.10,0.92,0.03,0.03];
    amp_txt_pos = [0.02,0.80,0.08,0.05];
    amp_pos= [0.10,0.81,0.03,0.03];
    %% setup graphics
    main_fig = figure('Name', '12 Lead ECG Viewer','Units','normalized','Position',[0 0 0.85 0.85]);
    main_ax = axes('Units','normalized','Position',main_ECG_pos);
    scroll_plt_ax = axes('Units','normalized','Position',scroll_ECG_pos);
    
    %% setup UI items
    get_file_btn = uicontrol('Style','pushbutton','units','normalized',...
                             'position',getfile_pos,'String','Load ECG file',...
                             'FontWeight','bold','FontSize',fontsize+1);
    get_file_txt= uicontrol('Style','text','units','normalized',...
                             'position',getfiletxt_pos,'String',graph_var.file_id,...
                             'FontWeight','bold','FontSize',fontsize);
    slider = uicontrol('Style','slider','Units','normalized',...
                        'Position',scroll_pos);

    scale_txt = uicontrol('Style','text','units','normalized',...
                       'position',plot_scale_pos,'String','scale: 100uV/box,40ms/box',...
                       'FontWeight','bold','FontSize',fontsize+1);
    plot_10sec_btn = uicontrol('Style','pushbutton','Units','normalized',...
                         'Position',plot_10sec_btn_pos,'String','Select Lead',...
                         'FontWeight','bold','FontSize',fontsize);
    fs_input = uicontrol('Style','edit','units','normalized',...
                       'position',fs_pos,'String',num2str(500),...
                       'FontWeight','bold','FontSize',fontsize);
    fs_txt = uicontrol('Style','text','units','normalized',...
                       'position',fs_txt_pos,'String','Sampling Frequency :  ',...
                       'FontWeight','bold','FontSize',fontsize);
    amp_input = uicontrol('Style','edit','units','normalized',...
                       'position',amp_pos,'String',num2str(1),...
                       'FontWeight','bold','FontSize',fontsize);
    amp_txt = uicontrol('Style','text','units','normalized',...
                       'position',amp_txt_pos,'String','Amplitude Resolution (uV) :  ',...
                       'FontWeight','bold','FontSize',fontsize);               
                   
                   
    %% ui callback 
    get_file_btn.Callback = @(src,eventdata)get_file(src,eventdata);
    slider.Callback = @(src,eventdata)scroll(src,eventdata);
    plot_10sec_btn.Callback = @(src,eventdata)plot_10sec(src,eventdata);
    
    %% ui handling function
    function get_file(src,eventdata)
        % get file txt
        [txtFile, txtPath] = uigetfile('*.txt*','Please select files for viewing');
        graph_var.ecg = read_txt(fullfile(txtPath,txtFile));
        graph_var.fullpath = fullfile(txtPath,txtFile);
        plot_ecg(src,eventdata)
        filename = strsplit(txtFile,'.');
        graph_var.file_id = filename{1};
        get_file_txt.String = filename{1};
        
    end

    function plot_ecg(src,eventdata)
        graph_var.fs = str2double(fs_input.String);
        % extract data from ecg textfile
        graph_var.ecg_mat = read_txt(graph_var.fullpath);
        % join ecg data with offset based on the scale
        graph_var.ecg_pink = ecg_2sec(graph_var.ecg_mat);
        graph_var.amp = str2double(amp_input.String);
        % clear the scroll axis
        cla(scroll_plt_ax)
        % set current main axes and plot
        axes(main_ax)
        plot(graph_var.ecg_pink,'k')
        hold on
        % make major plot grid
        ylim = main_ax.YLim;
        xlim = main_ax.XLim;
        main_gridx= [0:0.2*graph_var.fs:10*graph_var.fs;0:0.2*graph_var.fs:10*graph_var.fs];
        main_gridy = [ylim(1):500/graph_var.amp:ylim(2),ylim(1):500/graph_var.amp:ylim(2)];
        minor_gridx= [0:0.04*graph_var.fs:10*graph_var.fs;0:0.04*graph_var.fs:10*graph_var.fs];
        minor_gridy = [ylim(1):100/graph_var.amp:ylim(2),ylim(1):100/graph_var.amp:ylim(2)];
        % plot grid major and minor
        % colour code [r g b alpha]
        plot(main_gridx,[ones(1,size(main_gridx,2))*ylim(1);ones(1,size(main_gridx,2))*ylim(2)],...
             'Color',[1 0 0 0.4],'LineWidth',1)
        plot(minor_gridx,[ones(1,size(minor_gridx,2))*ylim(1);ones(1,size(minor_gridx,2))*ylim(2)],...
             'Color',[1 0 0 0.2],'LineWidth',0.01)
        plot([ones(1,size(main_gridy,2))*0;ones(1,size(main_gridy,2))*10*graph_var.fs],...
             [main_gridy;main_gridy],'Color',[1 0 0 0.4],'LineWidth',1)
        plot([ones(1,size(minor_gridy,2))*0;ones(1,size(minor_gridy,2))*10*graph_var.fs],...
             [minor_gridy;minor_gridy],'Color',[1 0 0 0.2],'LineWidth',0.01)

        % turn tick off
        set(main_ax,'TickLength',[0 0])
        main_ax.XTickLabel  = '';
        main_ax.YTickLabel  = '';
        
        n = 20; % the x axis text location shift @ first label columns
        m = 0; % shift of x axis location @ the rest of the labels
        seg_length = xlim(2)-xlim(1);
        x = [n,m+round(seg_length/4),m+round(seg_length/2),m+round(seg_length/4*3),...
            n,m+round(seg_length/4),m+round(seg_length/2),m+round(seg_length/4*3),...
            n,m+round(seg_length/4),m+round(seg_length/2),m+round(seg_length/4*3),n,n];
        % Make the y location based on the data's baseline
        plot_baseline = mean(graph_var.ecg_pink(2:30,:))-200;
        y = [[1 1 1 1].*plot_baseline(1),[1 1 1 1].*plot_baseline(2),...
             [1 1 1 1].*plot_baseline(3),plot_baseline(4),plot_baseline(5)];
        text(x,y,ECG_labels,'FontSize',label_size,'FontWeight','bold')
        
        % set y based on the baseline estimate. 
%         y_max = max(main_ax.YTick);
%         y = [(y_max/6*5-150),(y_max/6*5-150),(y_max/6*5-150),(y_max/6*5-150),...
%             (y_max/3*2-150),(y_max/3*2-150),(y_max/3*2-150),(y_max/3*2-150),...
%             (y_max/2-150),(y_max/2-150),(y_max/2-150),(y_max/2-150),...
%             (y_max/3-150),(y_max/6-150)];
        hold off
        main_ax.YLim(2) = max(max(graph_var.ecg_pink))+200;
        main_ax.YLim(1) = max(min(min(graph_var.ecg_pink)),min(min(graph_var.ecg_pink))-200);
        graph_var.x = x;
        graph_var.y = y;

    end
    
    function plot_10sec(src,eventdata)
%         lead_name = str2double(inputdlg('Please Enter the lead name'));
        [xx,yy] = ginput(1);
        % plot 10 second data of one lead
        % update when click is within the areas of the plots
        
        %{
        location for the plot 
        I(1)    avr(2)    v1(3)    v4(4)
        II(5)   avl(6)    v2(7)    v5(8)
        III(9)  avf(10)   v3(11)   v6(12)
        v1(13)
        II(14)
        %}
        
        ymin = 200;
        ymax = 400;
        xmin = graph_var.x(1)+10;
        xmax = 500;
        if xx<graph_var.x(1)+xmax && xx>graph_var.x(1)-xmin && yy<graph_var.y(1)+ymax &&yy>graph_var.y(1)-ymin 
            % lead I
            graph_var.ecg = graph_var.ecg_mat(:,1); 
        elseif xx<graph_var.x(5)+xmax && xx>graph_var.x(5)-xmin && yy<graph_var.y(5)+ymax &&yy>graph_var.y(5)-ymin 
            % lead II
            graph_var.ecg = graph_var.ecg_mat(:,2); 
        elseif xx<graph_var.x(3)+xmax && xx>graph_var.x(3)-xmin && yy<graph_var.y(3)+ymax &&yy>graph_var.y(3)-ymin 
            % lead v1
            graph_var.ecg = graph_var.ecg_mat(:,3);
        elseif xx<graph_var.x(7)+xmax && xx>graph_var.x(7)-xmin && yy<graph_var.y(7)+ymax &&yy>graph_var.y(7)-ymin 
            % lead v2
            graph_var.ecg = graph_var.ecg_mat(:,4);
        elseif xx<graph_var.x(11)+xmax && xx>graph_var.x(11)-xmin && yy<graph_var.y(11)+ymax &&yy>graph_var.y(11)-ymin  
            % lead v3
            graph_var.ecg = graph_var.ecg_mat(:,5);
        elseif xx<graph_var.x(4)+xmax && xx>graph_var.x(4)-xmin && yy<graph_var.y(4)+ymax &&yy>graph_var.y(4)-ymin
            % lead v4
            graph_var.ecg = graph_var.ecg_mat(:,6);
        elseif xx<graph_var.x(8)+xmax && xx>graph_var.x(8)-xmin && yy<graph_var.y(8)+ymax &&yy>graph_var.y(8)-ymin 
            % lead v5
            graph_var.ecg = graph_var.ecg_mat(:,7);
        elseif xx<graph_var.x(12)+xmax && xx>graph_var.x(12)-xmin && yy<graph_var.y(12)+ymax &&yy>graph_var.y(12)-ymin 
            % lead v6
            graph_var.ecg = graph_var.ecg_mat(:,8);
        elseif xx<graph_var.x(9)+xmax && xx>graph_var.x(9)-xmin && yy<graph_var.y(9)+ymax &&yy>graph_var.y(9)-ymin 
            % lead III
            graph_var.ecg = graph_var.ecg_mat(:,9);
        elseif xx<graph_var.x(2)+xmax && xx>graph_var.x(2)-xmin && yy<graph_var.y(2)+ymax &&yy>graph_var.y(2)-ymin 
            % lead avR
            graph_var.ecg = graph_var.ecg_mat(:,10);
        elseif xx<graph_var.x(6)+500 && xx>graph_var.x(6)+500 && yy<graph_var.y(6)+500 &&yy>graph_var.y(6)+500 
            % lead avL
            graph_var.ecg = graph_var.ecg_mat(:,11);
        elseif xx<graph_var.x(10)+xmax && xx>graph_var.x(10)-xmin && yy<graph_var.y(10)+ymax &&yy>graph_var.y(10)-ymin 
            % lead avF
            graph_var.ecg = graph_var.ecg_mat(:,12);
        elseif xx<graph_var.x(13)+xmax && xx>graph_var.x(13)-xmin && yy<graph_var.y(13)+ymax &&yy>graph_var.y(13)-ymin   
            % lead v1
            graph_var.ecg = graph_var.ecg_mat(:,3);
        elseif xx<graph_var.x(14)+xmax && xx>graph_var.x(14)-xmin && yy<graph_var.y(14)+ymax &&yy>graph_var.y(14)-ymin 
            % lead II
            graph_var.ecg = graph_var.ecg_mat(:,2);
        end
        % place holder for selecting based on the click
        axes(scroll_plt_ax)
        x_val = 1:1000;
        plot(x_val./graph_var.fs*1000,graph_var.ecg(1:1000),'k');
        xlabel('Time(ms)')
        ylabel('Voltage (uV)')
        grid(scroll_plt_ax,'on')
        grid(scroll_plt_ax,'minor')
        scroll_plt_ax.GridColor = 'r';
        scroll_plt_ax.MinorGridColor = 'r';
        scroll_plt_ax.GridAlpha = 0.5;
        scroll_plt_ax.MinorGridAlpha = 0.15;
        scroll_plt_ax.MinorGridLineStyle = '-';
    end

    function scroll(src,eventdata)
        % update based on current data value
        slide_val = round(slider.Value*length(graph_var.ecg));
        axes(scroll_plt_ax)
        if slide_val<4002
            x_val = (slide_val+1:min(length(graph_var.ecg),slide_val+1000))./graph_var.fs*1000;
            plot(x_val,graph_var.ecg(slide_val+1:min(size(graph_var.ecg_mat,1),slide_val+1000))./graph_var.amp,'k');
        else
            x_val = (length(graph_var.ecg)-999:size(graph_var.ecg))./graph_var.fs*1000;
            plot(x_val,graph_var.ecg(length(graph_var.ecg)-999:size(graph_var.ecg))./graph_var.amp,'k');
        end
        % set xlim
        scroll_plt_ax.XLim = [x_val(1) x_val(end)];
        xlabel('Time(ms)')
        ylabel('Voltage (uV)')
        grid(scroll_plt_ax,'on')
        grid(scroll_plt_ax,'minor')
        scroll_plt_ax.GridColor = 'r';
        scroll_plt_ax.MinorGridColor = 'r';
        scroll_plt_ax.GridAlpha = 0.5;
        scroll_plt_ax.MinorGridAlpha = 0.15;
        scroll_plt_ax.MinorGridLineStyle = '-';
        
    end
    
    function select_beat(src,eventdata)
    end
    %% appended function
    function ecg_mat = read_txt(txt_path)
        % function that reads in txt file for 12 lead ECG and output matrix
        % of the datafunction read_12lead_med_txt(filename, save_fname)
        delimiter = ' ';
        startRow = 2;
        formatSpec = '%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';
        fileID = fopen(txt_path,'r');
        textscan(fileID, '%[^\n\r]', startRow-1, 'ReturnOnError', false);
        dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'EmptyValue' ,NaN,'ReturnOnError', false);
        fclose(fileID);
        ecg_mat = [dataArray{1:end-1}];
    end
    
    function ecg_12L_2sec = ecg_2sec(ecg_mat)
        mmax = max(max(ecg_mat))*1.3;
        disp(mmax)
        % set plot offset
        if max(max(ecg_mat))*1.3 > 2000
            plot_offset = round(max(max(ecg_mat))*1.3/str2double(amp_input.String));
        elseif max(max(ecg_mat))*1.3 <1500
            plot_offset = round(2000/str2double(amp_input.String));
        else 
            plot_offset = round(2300/str2double(amp_input.String));
        end
        n = round(size(ecg_mat,1)./4)*4;
        % size checking for concatenating the matrix
        if n>size(ecg_mat,1)
            v1 = [ecg_mat(:,3);zeros(n-size(ecg_mat,1),1)];
            II = [ecg_mat(:,2);zeros(n-size(ecg_mat,1),1)];
        elseif n<size(ecg_mat,1)
            v1 = ecg_mat(1:n,3);
            II = ecg_mat(1:n,2);
        else
            v1 = ecg_mat(:,3);
            II = ecg_mat(:,3);
        end
        mm = round(size(ecg_mat,1)./4);
        ecg2sec1 = ecg_mat(1:mm,[1 2 9]); 
        ecg2sec1m = -mean(ecg2sec1);
        %ecg2sec1(1,:) = 800;
        ecg2sec2 = ecg_mat(mm+1:2*mm,[10 11 12]);
        ecg2sec2m = mean(ecg2sec2);
        ecg2sec2(1,:) = 1000;
        ecg2sec3 = ecg_mat(2*mm+1:3*mm,[3 4 5]);
        ecg2sec3m = mean(ecg2sec3);
        ecg2sec3(1,:) = 1000;
        ecg2sec4 = ecg_mat(3*mm+1:end,[6 7 8]);
        ecg2sec4m = mean(ecg2sec4);
        ecg2sec4(1,:) = 1000;

        
        graph_var.ax_mean1 = ecg2sec1m;
        graph_var.ax_mean2 = ecg2sec2m;
        graph_var.ax_mean3 = ecg2sec3m;
        graph_var.ax_mean4 = ecg2sec4m;
        m = 0.75;
        % make an offset matrix of the data for plotting
        ecg_12L_2sec = [[ecg2sec1(:,1)-ecg2sec1m(1);ecg2sec2(:,1)-ecg2sec2m(1);ecg2sec3(:,1)-ecg2sec3m(1);ecg2sec4(:,1)-ecg2sec4m(1)]+plot_offset*5*m,...
                        [ecg2sec1(:,2)-ecg2sec1m(2);ecg2sec2(:,2)-ecg2sec2m(2);ecg2sec3(:,2)-ecg2sec3m(2);ecg2sec4(:,2)-ecg2sec4m(2)]+plot_offset*4*m,...
                        [ecg2sec1(:,3)-ecg2sec1m(3);ecg2sec2(:,3)-ecg2sec2m(3);ecg2sec3(:,3)-ecg2sec3m(3);ecg2sec4(:,3)-ecg2sec4m(3)]+plot_offset*3*m,...
                         v1+plot_offset*2*m,II+plot_offset*1*m];
        
    end

end