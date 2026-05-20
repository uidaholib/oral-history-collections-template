
# Remediation Workflows

- If you have a copy of the repo on your local, select the + sign in your terminal to open a new window in bash and select these workflows as needed.

- Copy and Paste these formulas down into a Doc and replace the dummy path for the path of the file you would like to adjust. To find your file's path, right click the transcript file and select `copy path`.

# Python Workflows

- **cluster.py** consolidates rows of dialogue that are labeled as the same speaker into a maximum of four sentences for material that is over-parsed.

- **said.py** fixes a weakness in some of the Whisper scripts where an interviewee is mis-identified as the interviewer is posing questions. This frequently comes up if a speaker is prone to recounting things like "... and then she said, why did you do that?". On running the script, these phrases are identified and the speaker column is replaced with `interviewee`, which you can find and replace with that interviewees name after running the script.

## To run Python Scripts:

- Confirm in the VS Code terminal: 

Windows:

python --version

Mac:

python3 --version

- If you don't have a version newer than  3.8, visit the uidaho / Microsoft store and install the most recent update.

**In Bash**

Windows:

python -m venv .venv
source .venv/Scripts/activate

Mac:

python3 -m venv .venv
source .venv/bin/activate

**Replace with the path of the file you want to adjust**

Windows:

python cluster.py /c/Users/aweymouth/Documents/GitHub/oral-history-collections-template/_data/transcripts/flodin_elmer_2.csv
python said.py    /c/Users/aweymouth/Documents/GitHub/oral-history-collections-template/_data/transcripts/flodin_elmer_2.csv

Mac:

python3 cluster.py /Users/aweymouth@uidaho.edu/Documents/GitHub/oral-history-collections-template/_data/transcripts/flodin_elmer_2.csv
python3 said.py    /Users/aweymouth@uidaho.edu/Documents/GitHub/oral-history-collections-template/_data/transcripts/flodin_elmer_2.csv

# Other Workflows

## To remove millisecond from Premiere transcripts:

sed -i '' 's/\([0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\):[0-9]\{2\}/\1/g' /Users/aweymouth@uidaho.edu/Documents/GitHub/oral-history-collections-template/_data/transcripts/flodin_elmer_2.csv 

(select CSV that needs adjusting and choose `copy path` and paste in the last section of the command)

## To switch columns C and D (retain but not focus on End Time field if this is a Premiere Transcript)

python3 -c "
import csv, sys
rows = list(csv.reader(open('$(echo /Users/aweymouth@uidaho.edu/Documents/GitHub/oral-history-collections-template/_data/transcripts/mckeever_george_1.csv)')))
out = [[r[0],r[1],r[3],r[2]]+r[4:] if len(r)>3 else r for r in rows]
csv.writer(open('$(echo /Users/aweymouth@uidaho.edu/Documents/GitHub/oral-history-collections-template/_data/transcripts/mckeever_george_1.csv)','w',newline='')).writerows(out)
"

## To remove empty line breaks from CSV (occasional Premiere bug)

python3 -c "
import csv
path = '/Users/aweymouth@uidaho.edu/Documents/GitHub/oral-history-collections-template/_data/transcripts/mckeever_george_1.csv'
rows = list(csv.reader(open(path)))
clean = [r for r in rows if any(field.strip() for field in r)]
csv.writer(open(path, 'w', newline='')).writerows(clean)
"

## Capitalize the first letter in a new row of dialogue (occasional Premiere and Whisper bug)

perl -i -pe 's/"([a-z])/\"\u$1/g' /Users/aweymouth@uidaho.edu/Documents/GitHub/oral-history-collections-template/_data/transcripts/platz_ima_1.csv

## Change speaker names for specific sections:

awk 'BEGIN{FS=OFS=","} {gsub(/\r/,"")} NR>=66 && NR<=149 && $1=="Karen Purtee" {$1="Helena Cartwright Carlson"} 1' \
  "/Users/aweymouth/Documents/GitHub/oral-history-collections-template/_data/transcripts/carlson_helena_2.csv" > \
  "/Users/aweymouth/Documents/GitHub/oral-history-collections-template/_data/transcripts/tmp.csv" && \
  mv "/Users/aweymouth/Documents/GitHub/oral-history-collections-template/_data/transcripts/tmp.csv" \
     "/Users/aweymouth/Documents/GitHub/oral-history-collections-template/_data/transcripts/carlson_helena_2.csv"
