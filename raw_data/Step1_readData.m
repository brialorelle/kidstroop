function analyzeSizeStroop_Children()
dbstop if error;
clear; clc; close all;

% setup
fileName=mfilename('fullpath'); [homedir,x,x]=fileparts(fileName);
addpath(genpath('HelperCode'))


%% Options
loadData=1% %loading the data from scratch ? takes forever.
trimData=1; 
saveData=1; % saving output data?


%% Which trim type?
trimGlobalOnly=1; % Excludes RTs greater than 4 seconds%
minTrialsPerCond=4; % 5 or more trials PER CONDITION, gets > than this value...
 

%% Which experiment?
 Exp=1; % all kids, 80 children
% Exp=2;

%% Load data
if Exp==1
    expStr='Experiment1_80children'; exppath=[homedir filesep expStr]; datapath=[exppath filesep 'AllData'];
    avgFileName=[homedir filesep 'Outputs-Results' filesep expStr date '.mat'];
    S=dload_mturk([homedir filesep 'Experiment1_80children' filesep 'SubjectsToLoad' filesep 'SubjectsToLoad.csv']);

    if loadData
        cd (datapath); datafiles=S.FileName; Ages=S.Age;
        D=loadAllData(datafiles,datapath);
        save([homedir filesep 'Outputs-CompiledData/Experiment1_80children.mat'],'D')
    else
        load([homedir filesep 'Outputs-CompiledData/Experiment1_80children.mat']);
    end
    
elseif  Exp==2
    expStr='Experiment2_Replicate4YearOlds';
    datapath=[homedir filesep expStr filesep 'DataFiles']; 
    datafiles = dir([datapath filesep '*.txt']); 
    numSubs=length(datafiles);
    if loadData
        D=loadAllData(datafiles,datapath);
        save([homedir filesep 'Outputs-CompiledData/Experiment2_Replicate.mat'],'D')
    else
        load([homedir filesep 'Outputs-CompiledData/Experiment2_Replicate.mat'])
    end
    

    avgFileName=[homedir filesep 'Outputs-Results' filesep expStr trimString date '.mat'];
    
end


%% Save it!
if saveData
    disp('saving data...')
    DAllSubs=mergeDstructs(D); 
    % save as csv files as well
    dwrite(DAllSubs,[homedir filesep 'Outputs-CSV' filesep expStr 'Untrimmed' date '.csv']);
end

end



%%%%% subfunctions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [D]=loadData(datafiles,i)
        
        % accomodates fullfile vs. filestring formats...
        try
            data = json2mat(datafiles(i).name);
        catch
            data = json2mat(datafiles{i});
        end
        
        trialNames=fieldnames(data);
        
        for trial=1:length(trialNames)
            currTrial=getfield(data, trialNames{trial});
            D.id{trial}=currTrial.id;
            D.correctSide(trial)=str2num(currTrial.correctSide);
            D.trial(trial)=trial;
            D.sub(trial)=i;
            D.condition(trial)=str2num(currTrial.trialType);
            
            if isfield(currTrial,'RT')
                D.RT(trial)=currTrial.RT;
                D.correct(trial)=currTrial.Correct;
                
            else
                D.RT(trial)=NaN;
                D.correct(trial)=NaN;
                
            end

            D.leftImage{trial}=getImNum(currTrial.leftImage);
            D.rightImage{trial}=getImNum(currTrial.rightImage);
            
            D.imagePair(trial)=str2num(D.leftImage{trial}(1:2));
            D.imagePairCheck(trial)=str2num(D.rightImage{trial}(1:2));
            D.category{trial}=currTrial.category;
            
            if strcmp(D.category(trial),'Big-visBig')
                D.categoryNum(trial)=1;
                D.sizeNum(trial)=1;
            elseif strcmp(D.category(trial),'Big-visSmall')
                D.categoryNum(trial)=2;
                D.sizeNum(trial)=1;
                
            elseif strcmp(D.category(trial),'Small-visSmall')
                D.categoryNum(trial)=3;
                D.sizeNum(trial)=2;
                
            elseif strcmp(D.category(trial),'Small-visBig')
                D.categoryNum(trial)=4;
                D.sizeNum(trial)=2;
            end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function imNum=getImNum(imageName)
    idx=strfind(imageName,'/');
    lastSlash=idx(end);
    imNum=imageName(lastSlash+1:end-4);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DAll=loadAllData(datafiles,datapath)
    cd(datapath);
    numSubs=length(datafiles);
    for i=1:numSubs
        D=loadData(datafiles,i);
        DAll{i}=D; 
    end
end

function [DtrimAll]=trimDataGlobal(DAll)
    numSubs=length(DAll);
    for i=1:numSubs
        D=DAll{i};
        [DtrimAll{i}]=trim_global_outliers(D,{'correct==0','RT>4000','trial<11'});
    end
end

function [DtrimAll]=trimDataIndivOnly(DAll,SD,trimType)
    numSubs=length(DAll);
    for i=1:numSubs
        D=DAll{i};
        DtrimAll{i}=trim_outliers(D,SD,'RT',trimType,{'correct==0','trial<11'},{'condition'},'test.csv');   
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DtrimCat=mergeDstructs(DtrimAll)
    fieldNames=fieldnames(DtrimAll{1});

    for sub=1:size(DtrimAll,2)
        for currField=1:length(fieldNames)
            currFieldName=fieldNames{currField};
            if sub==1
                DtrimCat.(currFieldName)(1,:)=DtrimAll{sub}.(currFieldName);
            else
                DtrimCat.(currFieldName)(1,end+1:(end+length(DtrimAll{sub}.RT)))=DtrimAll{sub}.(currFieldName);
            end
        end
    end
end


