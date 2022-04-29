require 'csv'

source_data_csv = ARGV[0]

unless source_data_csv
  puts 'Usage: generate_schedule source_data.csv'
  exit
end

# constants to make it easier to pull data out of a row of the CSV
MENTOR = 0
DAY = 1
AMPM = 2
COMPANY_1 = 3
COMPANY_2 = 4
COMPANY_3 = 5
COMPANY_4 = 6
COMPANY_5 = 7
COMPANY_6 = 8

NO_OPEN_TIME = -1

def find_time_slot mentor_schedule, fellow_schedule
  time_slot = 0

  # walk through both schedules to find the first slot that is empty for both
  mentor_schedule.each_with_index do |_, time_slot|
    if mentor_schedule[time_slot] == nil && fellow_schedule[time_slot] == nil
      # if we found a time slot that is empty for the mentor and the fellow, return it
      return time_slot
    end
  end

  # if we didn't find a time that works, return this value to communicate that
  NO_OPEN_TIME
end


def schedule_time_block time_block_data
  # I want an array for each mentor with 9 slots (number of time slots I've decided are in a time block) - this is the mentor's schedule
  # I want an array for each company for each time block, with 9 slots - the company's schedule
  # puts time_block_data
  mentor_schedules = {}
  fellow_schedules = {}

  time_block_data.each do |mentor, fellow_list|
    # if that mentor has nothing scheduled yet for this time block, make an empty array for their schedule
    if !mentor_schedules[mentor]
      # puts "setting empty schedule for #{mentor}"
      mentor_schedules[mentor] = [nil, nil, nil, nil, nil, nil, nil, nil, nil]
      # "#{mentor}'s schedule: #{mentor_schedules[mentor]}"
    end

    fellow_list.each do |fellow|
      # if that mentor has nothing scheduled yet for this time block, make an empty array for their schedule
      if !fellow_schedules[fellow]
        # puts "setting empty schedule for #{fellow}"
        fellow_schedules[fellow] = [nil, nil, nil, nil, nil, nil, nil, nil, nil]
        # "#{fellow}'s schedule: #{fellow_schedules[fellow]}"
      end

      # pass in the current schedules to find the first mutually available time
      time_slot = find_time_slot mentor_schedules[mentor], fellow_schedules[fellow]

      # if we found a time that works, add the mentor and fellow to each other's schedules
      if time_slot != NO_OPEN_TIME
        mentor_schedules[mentor][time_slot] = fellow
        fellow_schedules[fellow][time_slot] = mentor
        # TODO: handle this case
        # if there was no open time
      end
    end
  end
  # puts mentor_schedules
  # puts fellow_schedules
end



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

# puts data_by_time_block
data_by_time_block.each_value do |ampm|
  ampm.each_value do |time_block_data|
    schedule_time_block(time_block_data)
  end
end
