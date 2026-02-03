import csv

"""
Simple I/O Library
  We assume all files are in UTF-8
"""
# Text
def read_text(file):
  """
  Read a file as text.  The name of the file is
  given as `file`.  The file is treated as utf-8
  format.

  The return type is a String.
  """
  with open(file, encoding='utf-8') as f:
    return f.read()
  return ''
def write_text(file, data):
  """
  Write the data into a file as text.  The name
  of the file is given as `file`.  The data is
  given as `data`.  The file is treated as utf-8
  format.

  There is no return value.
  """
  with open(file, 'w', encoding='utf-8') as f:
    f.write(data)

# CSV
def read_csv(file):
  """
  Read a file as comma-separated value (csv).
  The name of the file is given as `file`.  The
  file is treated as utf-8 format.

  The return type is a list-of-list.
  """
  res = []
  with open(file, encoding='utf-8') as f:
    rd = csv.reader(f)
    for row in rd:
      res.append(row)
  return res
def write_csv(file, data):
  """
  Write the data into a file as a comma-separated
  value (csv).  The name of the file is given as
  `file`.  The data is given as `data`.  The file
  is treated as utf-8 format.  The data is treated
  as a list-of-list.

  There is no return value.
  """
  with open(file, 'w', encoding='utf-8') as f:
    wt = csv.write(f, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    for row in data:
      wt.writerow(row)


"""
Helper functions
"""
def as_str(v):
  """
  Return the value as a string that can be
  accepted by postgresql as string.
  """
  s = f'{v}'.replace("'", "''")
  return f"'{s}'"
def as_int(v):
  """
  Return the value as a string that can be
  accepted by postgresql as integer.
  """
  return f'{v}'


"""
EXAMPLE
  Study the following example on how to process
  the csv file and write a file containing the
  INSERT statements.
"""
def process_new(file, out):

  # reading the data
  data = read_csv(file)[1:] # ignore column names row

  countries = {} # country_code: (country_name, country_region)
  teams = {} # team_name: country_code
  riders = {} # rider_bib : (rider_name, rider_dob, country_code, team_name)
  locations = {} # location_name : country_code
  stages = {} # stage_number: (stage_type, stage_length, stage_day, start_location, end_location)
  results = []

  # process line by line
  for day, stage, bib, rank, time, bonus, penalty, start_location, start_country_code, start_country_name, start_region, finish_location, finish_country_code, finish_country_name, finish_region, length, type, rider, team, dob, rider_country_code, rider_country_name, rider_region, team_country_code, team_country_name, team_region in data:
    
    if int(stage) != 1: # only require stage 1 data for project 1
      continue

    # countries
    countries[start_country_code] = (start_country_name, start_region)
    countries[finish_country_code] = (finish_country_name, finish_region)
    if rider_country_code: # a rider can have no country so will require this check
      countries[rider_country_code] = (rider_country_name, rider_region)
    countries[team_country_code] = (team_country_name, team_region)

    # teams
    teams[team] = team_country_code

    # riders
    riders[int(bib)] = (rider, dob, rider_country_code, team)

    # locations
    locations[start_location] = start_country_code
    locations[finish_location] = finish_country_code

    # stages
    stages[int(stage)] = (type, int(length), day, start_location, finish_location)

    # results
    results.append(
      (int(time), int(bonus), int(penalty), int(rank), int(bib), int(stage))
    )

    # the expected output
  sql = '''--
-- Group Number: 65
-- Group Members:
--   1. Brian Hu
--   2. Lee Jun Heng
--   3. Lip Pink Ray
--   4. Toh Keng Hian
--
'''
  # country table
  sql += "\n-- country table\n"
  for code, (name, region) in countries.items():
    sql += f"INSERT INTO country VALUES ({as_str(code)}, {as_str(name)}, {as_str(region)});\n"

  # team table
  sql += "\n-- team table\n"
  for team, code in teams.items():
    sql += f"INSERT INTO team VALUES ({as_str(team)}, {as_str(code)});\n"

  # rider table
  sql += "\n-- rider table\n"
  for bib, (name, dob, country_code, team) in riders.items():
    country_code = as_str(country_code) if country_code else "NULL"
    sql += f"INSERT INTO rider VALUES ({as_int(bib)}, {as_str(name)}, {as_str(dob)}, {country_code}, {as_str(team)});\n"
  
  # location table
  sql += "\n-- location table\n"
  for loc, code in locations.items():
    sql += f"INSERT INTO location VALUES ({as_str(loc)}, {as_str(code)});\n"
  
  # stage table
  sql += "\n-- stage table\n"
  for stage_num, (stage_type, length, day, start, end) in stages.items():
    sql += f"INSERT INTO stage VALUES ({as_int(stage_num)}, {as_str(stage_type)}, {as_int(length)}, {as_str(day)}, {as_str(start)}, {as_str(end)});\n"
    
  # result table
  sql += "\n-- result table\n"
  for time, bonus, penalty, rank, bib, stage_num in results:
    sql += f"INSERT INTO result VALUES ({as_int(time)}, {as_int(bonus)}, {as_int(penalty)}, {as_int(rank)}, {as_int(bib)}, {as_int(stage_num)});\n"
        

  # write into a file
  write_text(out, sql)

def process_additional(file, out):

  # reading the data
  data = read_csv(file)[1:] # ignore column names row

  exits = {} # rider_bib : (exit_reason, stage_number)

  # process line by line
  for bib, stage, reason in data:
    if int(stage) != 1:  # only require stage 1 data for project 1
      continue
    exits[bib] = (stage, reason)
    
  # the expected output
  sql = read_text(out)

  # exit table
  sql += "\n-- exit table\n"
  for bib, (stage, reason) in exits.items():
    sql += f"INSERT INTO exit VALUES ({as_str(reason)}, {as_int(bib)}, {as_int(stage)});\n"
        

  # write into a file
  write_text(out, sql)

# Change the input filename and/or the output filename
process_new('tdf-2025.csv', 'P01-data.sql')
process_additional('tdf-exits.csv', 'P01-data.sql')
