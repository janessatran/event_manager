require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letters(id, form_letter)
  Dir.mkdir("output") unless Dir.exists? "output"

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers(num)
  num = num.to_s.delete('^0-9')
  unless num.length >= 10
    if num == 11 
      num = (num[0] == 1 ? num[1..-1] : 'NA')
    elsif num == 10
      num = num
    else
      'NA'
    end
  end
  num.insert(3, '-').insert(-5, '-')
end

def clean_datetime(date)
  DateTime.strptime(date, '%m/%d/%y %H:%M')
end

def save_maxreg_hours(dates_array)
  Dir.mkdir("data") unless Dir.exists? "data"
  filename = 'data/max_registration_hours_' + DateTime.now.to_s + '.csv'
  record_date = DateTime.now.strftime "%d/%m/%Y %H:%M"
  max_hour = get_max_hour(dates_array)
  max_day = get_max_day(dates_array)
  record = CSV.open(filename, 'w') do |csv|
    csv << ['DateTime Recorded', 'Max Registration Hour', 'Max Registration Day of Week']
    csv << [record_date.to_s, max_hour.to_s, max_day.to_s]
  end
end

def get_max_hour(arr)
  arr.max.hour
end

def get_max_day(arr)
  arr.max.wday
end

def append_datearray(arr, date)
  arr << date
end

puts 'EventManager Intialized.'

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol
template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter
dates_array = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_numbers(row[:homephone])
  dates_array = append_datearray(dates_array, clean_datetime(row[:regdate]))

  form_letter = erb_template.result(binding)

  save_thank_you_letters(id, form_letter)
end
puts 'Storing max reg date...'
save_maxreg_hours(dates_array)

