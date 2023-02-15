#!/usr/bin/env python3
# merged_output.py

"""Parse through a gene bank file and extract the following protocluster feature data:
sequence_id
category
product
seq_start
seq_end
nucl_length

Parse through a tsv file and extract the following data columns:
sequence_id
nucl_start
nucl_end
nucl_length
num_proteins
product_activity
product_class
deepbgc_score
write all data to an output file in csv format"""

# import sys
# import argparse
# import csv
import os
import json
import Bio
from Bio import SeqIO



base_dir="/EFS/RunsInProgress/BGC_bacteria/20221109155838/BGC_unran_bacterial_samples"
sample_names = os.listdir('/EFS/RunsInProgress/BGC_bacteria/20221109155838/BGC_unran_bacterial_samples/')

header = [
	'SBI ID',
	'tool',
	'sequence_id',
	'Category',
	'Product',
	'start',
	'end',
	'nucl_length',
	'num_proteins',
	'product_activity',
	'product_class',
	'deepbgc_score'
]

Out_File = ('/EFS/RunsInProgress/BGC_bacteria/20221109155838/BGC_unran_bacterial_samples/summary_output.csv')
with open(Out_File, 'w') as o:
	o.write(",".join(header))
	o.write('\n')

for sample_name in sample_names:
	print("processing "+ sample_name)
	if os.path.isdir(base_dir+"/"+sample_name):
		print("processing inputs")
		gbk_input = """%s/%s/antismash2/%s.gbk""" % (
				base_dir, sample_name, sample_name
		)
		tsv_input = """%s/%s/Deepbgc/Deepbgc.bgc.tsv""" % (base_dir, sample_name)
		json_input = """%s/%s/Bagel4/00.OverviewGeneTables.json""" % (base_dir, sample_name)


		# SBI_ID = os.environ["sample"]

		o = open(Out_File, 'a')

		# Parse genebank formatted file
		for record in SeqIO.parse(gbk_input, 'genbank'):
			print("processing gbk input")
			for feature in record.features:
				if feature.type == "protocluster":
					category = 'Unknown'
					product = 'Unknown'
					if 'category' in feature.qualifiers:
						category = feature.qualifiers['category'][0]
					if 'product' in feature.qualifiers:
						product = feature.qualifiers['product'][0]
					start = feature.location.start + 1
					end = feature.location.end
					length = end - start + 1
					line = ','.join([
						sample_name,
						'antismash',
						record.id,
						category,
						product,
						f'{start}',
						f'{end}',
						f'{length}',
						'',
						'',
						'',
						''
					])
					o.write(f'{line}\n')


		# Parse TSV formatted file
		if os.path.isfile(tsv_input):
			file_handle = open(tsv_input)
			file_handle.readline()
			for line in file_handle:
				cols = line.rstrip().split('\t')
				sequence_id = cols[0]
				start = int(cols[5])
				end = int(cols[6])
				length = int(cols[7])
				num_proteins = int(cols[8])
				product_activity = cols[12]
				product_class = cols[17]
				deepbgc_score = cols[11]
				line = ','.join([
					sample_name,
					'deepbgc',
					sequence_id,
					'',
					'',
					f'{start}',
					f'{end}',
					f'{length}',
					f'{num_proteins}',
					product_activity,
					product_class,
					deepbgc_score
				])
				o.write(f'{line}\n')


		# Parse json formatted file
		json_data = json.load(open(json_input))
		if 'ResultsTable' not in json_data:
			json_data['ResultsTable']= ''
		for obj in json_data["ResultsTable"]:
			start = obj["start"]
			end = obj["end"]
			product_class = obj["class"]
			line = ','.join([
				sample_name,
				'BAGEL',
				'',
				'',
				'',
				f'{start}',
				f'{end}',
				'',
				'',
				'',
				product_class,
				''
			])
			o.write(f'{line}\n')


		o.close()
		