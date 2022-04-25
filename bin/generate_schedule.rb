require 'csv'

source_data_csv = ARGV[0]

unless source_data_csv
  puts 'Usage: generate_schedule source_data.csv'
  exit
end
MENTOR = 0
DAY = 1
AMPM = 2
COMPANY_1 = 3
COMPANY_2 = 4
COMPANY_3 = 5
COMPANY_4 = 6
COMPANY_5 = 7
COMPANY_6 = 8

data_by_time_block = {}

CSV.foreach(source_data_csv, headers: true) do |row|
  # if we haven't seen this day yet, add it
  day = row[DAY]
  if !data_by_time_block[day]
    data_by_time_block[day] = {}
  end

  # if we haven't seen this ampm value for this day yet, add it
  ampm = row[AMPM]
  if !data_by_time_block[day][ampm]
    data_by_time_block[day][ampm] = {}
  end

  data_by_time_block[day][ampm][row[MENTOR]] = [row[COMPANY_1], row[COMPANY_2], row[COMPANY_3], row[COMPANY_4], row[COMPANY_5], row[COMPANY_6]]
end
