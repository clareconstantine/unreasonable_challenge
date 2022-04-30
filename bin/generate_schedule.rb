require 'csv'

source_data_csv = ARGV[0]

unless source_data_csv
  puts 'Usage: generate_schedule source_data.csv'
  exit
end


# ======================== CONSTANTS =========================================

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

UNDEFINED = "Undefined".freeze

# number of time slots for meetings in a time block
# we could also take a parameter for the number of time slots in a time block
# if that varies between programs
NUM_TIME_SLOTS = 9


# ======================== HELPER METHODS ====================================

# params: arrays representing a mentor's schedule and a fellow's schedule
# returns the first index that is empty in both arrays, representing the
# available meeting slot that works for both parties. Returns NO_OPEN_TIME
# if there was not a mutually available time
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

# params: an array of mentor names in the order that we want to schedule their meetings,
# and the mentor and fellow meeting data (to be scheduled) for a specific time block
# returns an object containing the mentor and fellow's schedules for the time block, or
# NO_OPEN_TIME if there wasn't a viable schedule
def schedule_from_mentor_list mentor_list, time_block_data
  # where we will store schedules for mentors and fellows
  mentor_schedules = {}
  fellow_schedules = {}

  mentor_list.each do |mentor|
    # if this mentor has no schedule yet for this time block, make an empty
    # array to represent their schedule - each space in the array represents a time
    # slot, and we will eventually fill in the names of the fellows they will be
    # meeting with in the time slots when they have meetings scheduled.
    if !mentor_schedules[mentor]
      mentor_schedules[mentor] = Array.new(NUM_TIME_SLOTS) {|i| nil}
    end

    # get the list of fellows that mentor is going to meet with
    fellow_list = time_block_data[mentor]

    # schedule the meeting between the mentor and each fellow in their list
    fellow_list.each do |fellow|
      # don't try and schedule a meeting unless this fellow exists (some mentors
      # don't have the max number of meetings, so there can be nil entries in
      # the fellow_list
      next if !fellow

      # if this fellow has no schedule yet for this time block, make an empty
      # array to represent their schedule - each space in the array represents a time
      # slot, and we will eventually fill in the names of the fellows they will be
      # meeting with in the time slots when they have meetings scheduled.
      if !fellow_schedules[fellow]
        fellow_schedules[fellow] = Array.new(NUM_TIME_SLOTS) {|i| nil}
      end

      # pass in the mentor and fellow's schedules to find the first mutually available time
      time_slot = find_time_slot mentor_schedules[mentor], fellow_schedules[fellow]

      if time_slot == NO_OPEN_TIME
        # if we didn't find a time that works, return this value to communicate that
        return NO_OPEN_TIME
      else
        # we found a time that works, add the mentor and fellow to each other's schedules
        mentor_schedules[mentor][time_slot] = fellow
        fellow_schedules[fellow][time_slot] = mentor
      end
    end
  end

  # we found a schedule that works, so return it
  {
    "mentor_schedules" => mentor_schedules,
    "fellow_schedules"=> fellow_schedules
  }
end

# params: the mentor and fellow meeting data (to be scheduled) for a specific time block
# returns an object containing the mentor and fellow's schedules for the time block
def schedule_time_block time_block_data
  # create a list of mentors, so we can schedule them in a different order if we don't get a viable schedule
  mentor_list = time_block_data.keys

  # I ran out of time, but my plan here was to sort the mentor list in decreasing order
  # of how many meetings they have during this time block, so that we always schedule the
  # busiest mentor's meetings first. If we couldn't create a compatible schedule, then
  # rotate this array and try again, until we've tried each of the starting points. Could
  # also think about shuffling randomly a few times after trying all of the roations if we
  # still don't have a working schedule. I also need to fully finish handling the NO_OPEN_TIME
  # value if we didn't find a valid schedule.
  # Could also add more time slots.

  schedule_from_mentor_list mentor_list, time_block_data
end




# ======================== MAIN ====================================


# we are going to group the CSV data by time block (ex: Monday AM) her
data_by_time_block = {}

# we will store the final schedules here
final_schedules = {}

# Iterate through the CSV, adding the data to data_by_time_block in the shape
# {"Monday":
#   {
#   "AM":
#     {"Ada Wong": ["Vyv", "ZolaSea"],
#       ...
#     }
#   "PM": {"Ada Wong": ["Vyv", "ZolaSea"],
#       ...
#     }
#   },
# "Tuesday":
#   ...
# }
CSV.foreach(source_data_csv, headers: true) do |row|
  day = row[DAY]
  ampm = row[AMPM]

  # skip scheduling mentors who have not confirmed their time block
  next if day == UNDEFINED || ampm == UNDEFINED

  # if we haven't seen this day yet, add it
  if !data_by_time_block[day]
    data_by_time_block[day] = {}
    final_schedules[day] = {}
  end

  # if we haven't seen this ampm value for this day yet, add it
  if !data_by_time_block[day][ampm]
    data_by_time_block[day][ampm] = {}
    final_schedules[day][ampm] = {}
  end

  data_by_time_block[day][ampm][row[MENTOR]] = [row[COMPANY_1], row[COMPANY_2], row[COMPANY_3], row[COMPANY_4], row[COMPANY_5], row[COMPANY_6]]
end

data_by_time_block.each do |day, ampm|
  ampm.each do |ampm, time_block_data|
    schedules = schedule_time_block(time_block_data)
    final_schedules[day][ampm] = schedules
  end
end

puts final_schedules
