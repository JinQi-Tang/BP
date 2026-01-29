classdef Logger < handle
    % LOGGER 自定义日志记录器 (支持指定路径版)
    % 
    % 更新说明：
    % 1. 构造函数增加 targetDir 参数，可指定 logs 文件夹的生成位置
    % 2. 静态方法 listSessions 支持查询指定位置的日志
    
    properties (SetAccess = private)
        SessionPath   
        LogFileID     
        LogFileName   
        DiaryFile     
        StartTimeObj  
    end
    
    methods
        function obj = Logger(experimentName, targetDir)
            % 构造函数
            % 输入: 
            %   experimentName (可选) - 实验名称
            %   targetDir (可选) - 日志存放的根目录。默认为当前目录 pwd
            
            if nargin < 1
                experimentName = 'Experiment';
            end
            
            % ---【修改点 1】处理目标路径 ---
            if nargin < 2 || isempty(targetDir)
                targetDir = pwd; % 默认为当前工作目录
            end
            
            % 1. 获取时间
            tNow = datetime('now');
            obj.StartTimeObj = tNow; 
            
            % 2. 定义 logs 文件夹 (在指定目录下)
            rootLogDir = fullfile(targetDir, 'logs');
            if ~exist(rootLogDir, 'dir')
                [status, msg] = mkdir(rootLogDir);
                if ~status
                    error('无法创建日志目录: %s\n原因: %s', rootLogDir, msg);
                end
            end
            
            % 3. 日期子目录
            dateStr = string(tNow, 'yyyy-MM-dd');
            dateFolder = fullfile(rootLogDir, dateStr);
            if ~exist(dateFolder, 'dir'), mkdir(dateFolder); end
            
            % 4. 会话目录
            timeStr = string(tNow, 'HHmmss');
            baseFolderName = sprintf('%s_%s', timeStr, experimentName);
            folderName = baseFolderName;
            
            counter = 1;
            while exist(fullfile(dateFolder, folderName), 'dir')
                folderName = sprintf('%s_%s_%d', experimentName, timeStr, counter);
                counter = counter + 1;
            end
            
            obj.SessionPath = fullfile(dateFolder, folderName);
            mkdir(obj.SessionPath);
            
            % 5. 初始化日志文件
            obj.LogFileName = fullfile(obj.SessionPath, 'general.log');
            
            % 使用 'n', 'UTF-8' 确保兼容性
            obj.LogFileID = fopen(obj.LogFileName, 'w', 'n', 'UTF-8');
            
            if obj.LogFileID == -1
                error('无法打开日志文件: %s', obj.LogFileName);
            end
            
            % 6. Diary
            obj.DiaryFile = fullfile(obj.SessionPath, 'solver_output.txt');
            diary('off');
            if exist(obj.DiaryFile, 'file'), delete(obj.DiaryFile); end
            diary(obj.DiaryFile);
            
            % 7. 初始信息
            obj.info('=== 日志会话已启动 ===');
            obj.info(sprintf('实验名称: %s', experimentName));
            obj.info(sprintf('启动时间: %s', string(tNow, 'yyyy-MM-dd HH:mm:ss')));
            obj.info(sprintf('根目录位置: %s', rootLogDir)); % 记录一下根目录位置
            obj.info(sprintf('完整保存路径: %s', obj.SessionPath));
        end
        
        function info(obj, message)
            tStr = string(datetime('now'), 'yyyy-MM-dd HH:mm:ss');
            logStr = sprintf('[%s] [INFO] %s\n', tStr, message);
            
            fprintf('%s', logStr); 
            if obj.LogFileID > 0
                fprintf(obj.LogFileID, '%s', logStr);
            end
        end
        
        function warning(obj, message)
            tStr = string(datetime('now'), 'yyyy-MM-dd HH:mm:ss');
            logStr = sprintf('[%s] [WARNING] %s\n', tStr, message);
            fprintf(2, '%s', logStr); 
            if obj.LogFileID > 0, fprintf(obj.LogFileID, '%s', logStr); end
        end
        
        function error(obj, message)
            tStr = string(datetime('now'), 'yyyy-MM-dd HH:mm:ss');
            logStr = sprintf('[%s] [ERROR] %s\n', tStr, message);
            fprintf(2, '%s', logStr);
            if obj.LogFileID > 0, fprintf(obj.LogFileID, '%s', logStr); end
        end
        
        function saveFigure(obj, figHandle, filename, varargin)
            if nargin < 3
                filename = sprintf('figure_%s.png', string(datetime('now'), 'HHmmss'));
            end
            fullPath = fullfile(obj.SessionPath, filename);
            [~, ~, ext] = fileparts(filename);
            try
                if any(strcmpi(ext, {'.png', '.jpg', '.jpeg', '.pdf', '.eps', '.tif'}))
                    if isempty(varargin)
                        exportgraphics(figHandle, fullPath, 'Resolution', 300);
                    else
                        exportgraphics(figHandle, fullPath, varargin{:});
                    end
                else
                    saveas(figHandle, fullPath);
                end
                obj.info(sprintf('图片已保存: %s', filename));
            catch ME
                obj.error(sprintf('图片保存失败: %s', ME.message));
            end
        end

        function saveData(obj, data, filename)
            if nargin < 3
                filename = sprintf('data_%s.mat', string(datetime('now'), 'HHmmss'));
            end
            fullPath = fullfile(obj.SessionPath, filename);
            try
                save(fullPath, 'data');
                obj.info(sprintf('数据已保存: %s', filename));
            catch ME
                obj.error(sprintf('数据保存失败: %s', ME.message));
            end
        end
        
        function saveJSON(obj, data, filename)
            if nargin < 3
                filename = 'results.json';
            end
            if ~endsWith(filename, '.json', 'IgnoreCase', true)
                filename = filename + ".json"; 
            end
            fullPath = fullfile(obj.SessionPath, filename);
            
            try
                jsonStr = jsonencode(data, 'PrettyPrint', true);
                
                % 修正的 fopen 写法
                fid = fopen(fullPath, 'w', 'n', 'UTF-8');
                
                if fid == -1
                    error('无法打开文件进行写入');
                end
                fprintf(fid, '%s', jsonStr);
                fclose(fid);
                obj.info(sprintf('JSON结果已保存: %s', filename));
            catch ME
                obj.error(sprintf('JSON保存失败: %s', ME.message));
            end
        end
        
        function sessionInfo = getSessionInfo(obj)
            sessionInfo = struct();
            sessionInfo.SessionPath = obj.SessionPath;
            sessionInfo.LogFileName = obj.LogFileName;
            sessionInfo.DiaryFile   = obj.DiaryFile;
            sessionInfo.StartTime   = obj.StartTimeObj;
        end
        
        function delete(obj)
            if isvalid(obj)
                runDuration = datetime('now') - obj.StartTimeObj;
                obj.info('=== 日志会话结束 ===');
                obj.info(sprintf('总运行耗时: %s', char(runDuration)));
                if obj.LogFileID > 0, fclose(obj.LogFileID); end
                diary off;
            end
        end
    end
    
    methods (Static)
        function list = listSessions(targetDir, dateStr)
            % LISTSESSIONS 列出日志
            % 用法: 
            %   Logger.listSessions() -> 列出当前目录下的日志
            %   Logger.listSessions('D:\MyLogs') -> 列出指定目录下的日志
            %   Logger.listSessions('D:\MyLogs', '2026-01-28') -> 列出指定日期
            
            if nargin < 1 || isempty(targetDir)
                targetDir = pwd;
            end
            
            rootLogDir = fullfile(targetDir, 'logs');
            if ~exist(rootLogDir, 'dir')
                fprintf('在 "%s" 下未找到 logs 文件夹。\n', targetDir);
                list = []; return;
            end
            
            if nargin < 2 || isempty(dateStr)
                % 列出所有
                folders = dir(rootLogDir);
                mask = [folders.isdir] & ~strncmp({folders.name}, '.', 1);
                dateFolders = folders(mask);
                
                fprintf('📂 日志根目录: %s\n', rootLogDir);
                for i = 1:length(dateFolders)
                    fprintf('\n📅 日期: %s\n', dateFolders(i).name);
                    % 递归调用显示子项
                    Logger.listSessions(targetDir, dateFolders(i).name);
                end
            else
                % 列出特定日期
                targetDateDir = fullfile(rootLogDir, dateStr);
                if ~exist(targetDateDir, 'dir'), return; end
                
                subs = dir(targetDateDir);
                mask = [subs.isdir] & ~strncmp({subs.name}, '.', 1);
                sessions = subs(mask);
                
                for k = 1:length(sessions)
                    fprintf('  └─ 📁 %s\n', sessions(k).name);
                end
                list = {sessions.name};
            end
        end
    end
end