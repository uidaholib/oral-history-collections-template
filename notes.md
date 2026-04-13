## Processing Notes

- To remove millisecond from Premiere transcripts: in bash -- sed -i '' 's/\([0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\):[0-9]\{2\}/\1/g' /Users/aweymouth@uidaho.edu/Documents/GitHub/oral-history-collections-template/_data/transcripts/flodin_elmer_2.csv (select CSV that needs adjusting and choose `copy path` and paste in the last section of the command)

- To switch columns C and D: 

python3 -c "
import csv, sys
rows = list(csv.reader(open('$(echo /Users/aweymouth@uidaho.edu/Documents/GitHub/oral-history-collections-template/_data/transcripts/mckeever_george_1.csv)')))
out = [[r[0],r[1],r[3],r[2]]+r[4:] if len(r)>3 else r for r in rows]
csv.writer(open('$(echo /Users/aweymouth@uidaho.edu/Documents/GitHub/oral-history-collections-template/_data/transcripts/mckeever_george_1.csv)','w',newline='')).writerows(out)
"

- To remove line breaks from CSV:

python3 -c "
import csv
path = '/Users/aweymouth@uidaho.edu/Documents/GitHub/oral-history-collections-template/_data/transcripts/mckeever_george_1.csv'
rows = list(csv.reader(open(path)))
clean = [r for r in rows if any(field.strip() for field in r)]
csv.writer(open(path, 'w', newline='')).writerows(clean)
"

## Diarization Trouble / Hallucination / Needs Reprocessing

- adair_ione_3: diarization trouble -- attributing Ione Adair to Sam
- albright_lora_1, albright_lora_2: diarization breaks down about an hour in
- bacca_jamesandamelia_1: diarization problems between two interviewees
- brocke_frank_3: hallucination
- brocke_frank_4: diarization problems around 20
- wurman_mamie_1: redirecting to lynd_mary_1
- wicks_grace_2 and wicks_grace_1 transcripts not processed
- clyde_lola_1: diarization breaks down around 28 minutes
- clyde_lola_4: diarization breaks down around 33 minutes
- daniels_eva_1: needs to be re-processed
- noticing frequent diarization confusion in second half of transcripts:
- waldron_kate_2: interviewee asking questions, causing diarization confusion
- fleener_dora_1: diarization breaks down around 26
- fry_frances_1: diarization breaks down around 58
- utt_emmettandanna_5 replaced premiere transcript; new transcript diarization breakdown with questions. some remediation done but could be reprocessed.
- utt_emmettandanna_4 premiere transcript could be replaced; new transcript diarization breakdown around questions
- glenn_royandmabel_1: Diarization issues
- goff_abe_2: Diarization issues
- gorman_madeleine_1: diarization breakdown at 48
- halen_alben_2: subtle diarization problems

## Never Processed

- demus_gus_3: mk processed
- gilder_glenandagnes_7: mk processed. a baby babbling in background that confuses the transcript

## Missing Audio

- wahl_tomandelizabeth_3 and wahl_tomandelizabeth_2
- vine_rannie_1
- martin_roy_1+2
- milbert_frank_1+2
- morris_mabell_1

## Incorrect Interviewer in Metadata

- glenn_bruceandagnes_1: marked as Sam but it is Laura
- baker_winney_1: very distorted and faint -- marked as Sam in metadata but it is Laura
- hardt_verna_1: appears to just be a dictated tape -- no interviewer
- johanson_nellie_1: Interviewer listed as Rachel Foxwell but it is Rachel Foxman -- https://objects.lib.uidaho.edu/latahlegacy/latahlegacy_v07-n4.pdf

## Included in _transcripts but not CSV

- byers_fannie_1: is there a reason this is not included in current CSV?
- lynd_mary_1

## Redundant Transcripts

- cornelison_bernadine_1-cornelison_bernadine_5 redirects to adair_ione_1-adair_ione_5, which are already replaced
- wurman_mamie is redirected to lynd_mary_1
- lemarr_may_2 redirects to justice_lena_2
- murphy_danandjoemaloney_1 is a copy of maloney_joe_1

## Sensitive Material
- utt_emmettandanna_5 00:18:36; 00:52:12

## Kind of incredible

- guilfoy_leo_2

## Translation notes

- jackson_alice_1: Nez Perce words that could use another look

## Misc.

- lawrence_floydandnola_2: Same audio seems to repeat from an hour into the recording. Also, a ton of cross-talk.
- buchanan_george_1: listed as transcript only but its just an index
- mahon_catherine_2: audio starts looping at 0:31:00-1:04:00



