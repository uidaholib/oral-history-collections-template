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

- To make sure all characters following a quote in the words field is capitalized

perl -i -pe 's/"([a-z])/\"\u$1/g' /Users/aweymouth@uidaho.edu/Documents/GitHub/oral-history-collections-template/_data/transcripts/platz_ima_1.csv

## Reprocess with new script

- brocke_frank_4: diarization problems around 20; premiere over-parses. aw - script c and d both failed - try again with large model with script_d (pending - run with three speakers)
- clyde_lola_4: diarization breaks down around 33 minutes; premiere over-parses. aw - script c and d both failed - try again with large model with script_d (pending - run with four speakers) -- attempted with script_c medium model and still faulty in diarization -- try with B?
- halen_alben_2: subtle diarization problems; premiere struggling with dialogue. Halen's wife also speaks in the interview but is not named in the metadata. aw - script c and d both failed - try again with large model with script_d (pending - run with three speakers)
- utt_emmettandanna_5: diarization breakdown with questions; premiere struggling with dialogue. aw - script c and d both failed - try again with large model with script_d (pending - run with three speakers)
- utt_emmettandanna_4: diarization breakdown with questions; premiere struggling with dialogue. aw - script c and d both failed - try again with large model with script_d (pending - run with three speakers)
- utt_emmettandanna_1 - diarization breakdown with questions; premiere struggling with dialogue. aw - script c and d both failed - try again with large model with script_d (pending - run with three speakers)
- sundberg_arthur_5: both f_script and Premiere failed. Will run with large model for two speakers (pending). -- attempted with script_c medium model and still faulty in diarization -- try with B?

## Missing Audio

- wahl_tomandelizabeth_3 
- wahl_tomandelizabeth_2
- vine_rannie_1
- wicks_grace_2
- wicks_grace_1
- sundberg_arthur_2
- sweeney_nellie_1
- martin_roy_1+2 (but correctly formatted)
- milbert_frank_1+2 (but correctly formatted)
- morris_mabell_1 (but correctly formatted)

## Incorrect Interviewer in Metadata

- glenn_bruceandagnes_1: marked as Sam but it is Laura
- baker_winney_1: very distorted and faint -- marked as Sam in metadata but it is Laura
- hardt_verna_1: appears to just be a dictated tape -- no interviewer
- johanson_nellie_1: Interviewer listed as Rachel Foxwell but it is Rachel Foxman -- https://objects.lib.uidaho.edu/latahlegacy/latahlegacy_v07-n4.pdf
- presby_curtis_1: marked as Sam but it is Laura

## Included in _transcripts but not CSV

- byers_fannie_1: is there a reason this is not included in current CSV?
- lynd_mary_1

## Redundant Transcripts

- cornelison_bernadine_1-cornelison_bernadine_5 redirects to adair_ione_1-adair_ione_5, which are already replaced
- wurman_mamie is redirected to lynd_mary_1
- lemarr_may_2 redirects to justice_lena_2
- murphy_danandjoemaloney_1 is a copy of maloney_joe_1
- platt_kenneth_1 bypasses to hickman_william_1
- sundell_theodore_1 redirects to asplund_ida_1

## Sensitive Material
- utt_emmettandanna_5 00:18:36; 00:52:12
- William (Michigan Bill) Stowell: likely all of the recordings

## Translation notes

- jackson_alice_1: Nez Perce words that could use another look

## Misc.

- lawrence_floydandnola_2: Same audio seems to repeat from an hour into the recording. Also, a ton of cross-talk.
- buchanan_george_1: listed as transcript only but its just an index
- mahon_catherine_2: audio starts looping at 0:31:00-1:04:00
- otness_lillian_1 recording turns into oslund_anna_1 recording at the hour mark: "I never did know what it was particularly that caused him to, to change. | There are the thoughts about this country, how great it is."
- clyde_lola_1: repeats section of interview at 01:32:06:08, original transcript shows that section of interview is missing
- ruberg_hilda_1: plays the same audio over again at the hour mark
- halen_alben_2: Starts part way through the interview. Original transcript shows that section of the iinterview is missing

## Design Notes

- The tagging elements can be a dropdown menu on the left of the Browse page rather than a tagging data visualization page
- The photographs of the interviewees should expand in a light box on selection

## Model notes

- There does appear to be innocuous hallucination that is occurring with only the large-V3 Whisper model. The small.en model hallucinations are much less frequent and much more obvious. The large model will improvise multiple sentences at the beginning of a passage and then return to the actual script seamlessly.


