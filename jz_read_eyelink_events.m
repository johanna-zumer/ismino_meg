function [event,data]=jz_read_eyelink_events(filename)
% .duration is in samples

hdr=ft_read_header(filename);
if isfield(hdr.orig,'dat')
  data=hdr.orig.dat;
else
  error('no time sample data in this .asc file')
end

if hdr.Fs~=2000
  error('see ft_read_header change')
end
% % not sure why this is needed on .asc files in eyelink_data folder but not
% % behav_data folder!
% tmp=hdr.TimeStampPerSample;
% hdr.TimeStampPerSample=1000/round(hdr.Fs);
% if hdr.TimeStampPerSample - tmp > 1e-06
%   error('hack broken');
% end

eind=0;
if isfield(hdr.orig,'efix')
  for ee=1:length(hdr.orig.efix)
    eind=eind+1;
    tok=tokenize(hdr.orig.efix{ee});
    tok(cellfun('isempty', tok))=[];
    event(eind).type='sfix';  % the marker goes at the start
    event(eind).timestamp=str2num(tok{3});
    event(eind).sample=(str2num(tok{3})-hdr.FirstTimeStamp)/hdr.TimeStampPerSample + 1;
    event(eind).value=str2num(tok{6});
    event(eind).duration=(str2num(tok{5}))/hdr.TimeStampPerSample + 1;
    event(eind).offset=0;
  end
end
if isfield(hdr.orig,'esacc')
  for ee=1:length(hdr.orig.esacc)
    eind=eind+1;
    tok=tokenize(hdr.orig.esacc{ee});
    tok(cellfun('isempty', tok))=[];
    event(eind).type='ssacc'; % the marker goes at the start
    event(eind).timestamp=str2num(tok{3});
    event(eind).sample=(str2num(tok{3})-hdr.FirstTimeStamp)/hdr.TimeStampPerSample + 1;
    event(eind).value=str2num(tok{10});
    event(eind).duration=(str2num(tok{5}))/hdr.TimeStampPerSample + 1;
    event(eind).offset=0;
  end
end
if isfield(hdr.orig,'eblink')
  for ee=1:length(hdr.orig.eblink)
    eind=eind+1;
    tok=tokenize(hdr.orig.eblink{ee});
    tok(cellfun('isempty', tok))=[];
    event(eind).type='sblink'; % the marker goes at the start
    event(eind).timestamp=str2num(tok{3});
    event(eind).sample=(str2num(tok{3})-hdr.FirstTimeStamp)/hdr.TimeStampPerSample + 1;
    event(eind).value=1;
    event(eind).duration=(str2num(tok{5}))/hdr.TimeStampPerSample + 1;
    event(eind).offset=0;
  end
end
if isfield(hdr.orig,'msg')
  for ee=1:length(hdr.orig.msg)
    tok=tokenize(hdr.orig.msg{ee});
    tok(cellfun('isempty', tok))=[];
    if strcmp(tok{3},'TRIGGER')
      eind=eind+1;
      event(eind).type='msg'; % the marker goes at the start
      event(eind).timestamp=str2num(tok{2});
      event(eind).sample=(str2num(tok{2})-hdr.FirstTimeStamp)/hdr.TimeStampPerSample + 1;
      event(eind).value=str2num(tok{4});
      event(eind).duration=1;
      event(eind).offset=0;
    end
  end
end

[~,sortind]=sort([event.sample]);
event=event(sortind);


