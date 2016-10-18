require 'csv'
# require 'open-uri'

# csv = open('http://s3.amazonaws.com/misc-ww/data.csv').readlines
csv = <<-CSV
  Capacity,MonthlyPrice,StartDay,EndDay
  1,600,2014-07-01,
  1,400,2014-04-02,
  1,400,2014-05-01,
  5,2800,2014-03-01,2014-04-30
  2,1500,2014-05-01,2014-06-30
  4,1700,2014-04-01,
  3,1300,2014-04-01,
  15,6500,2014-05-01,2014-08-31
  1,400,2014-05-01,
  1,400,2014-05-01,
  3,1400,2014-05-01,
  18,7200,2014-05-01,
  1,800,2014-06-01,
  1,700,2014-05-01,2014-06-30
  2,1250,2014-04-16,2014-06-02
  1,600,2013-11-01,2014-05-31
  8,4000,2014-06-02,2014-07-31
  2,1300,2014-05-01,2014-10-31
  4,2200,2014-05-01,
  14,11875,2014-06-01,
  2,1500,2014-05-01,2014-08-31
  2,1500,2012-06-01,
  3,1850,2014-04-09,2014-08-06
  2,1100,2014-05-01,2014-09-30
  1,625,2014-04-11,
  1,1000,2014-02-14,
  1,400,2014-05-01,
  6,3600,2014-04-02,
  2,950,2013-02-01,2014-05-31
  4,2500,2013-06-01,2014-04-30
  2,1200,2014-07-01,2014-08-31
  1,950,2014-06-01,2014-08-31
  4,3200,2014-04-01,2014-09-30
  1,400,2014-03-27,2014-04-10
  4,2600,2014-02-01,2014-04-08
  11,5500,2014-05-01,
  2,1200,2014-05-01,2014-07-02
  1,600,2014-05-01,2014-07-31
  1,800,2013-11-01,2014-04-30
  1,700,2013-05-01,
  2,900,2014-07-01,2014-08-31
  2,1400,2014-04-02,
  2,1500,2014-05-01,
  2,1200,2014-05-01,
  2,1500,2014-05-01,2014-10-31
  2,900,2014-02-01,
  1,400,2014-04-14,
  2,900,2014-01-01,2014-06-30
  2,1000,2013-12-01,2014-06-30
  9,4500,2014-02-06,2014-04-30
  4,2500,2013-08-01,
  6,2900,2013-05-01,2014-05-31
  1,600,2014-04-09,
  2,1700,2014-02-14,2014-04-30
  2,900,2014-07-01,
  1,400,2014-05-01,2014-10-31
  2,0,2014-04-15,2014-05-01
  4,2500,2014-05-01,
  4,3600,2014-05-01,
  9,4950,2014-05-01,
  2,1100,2014-05-12,
  6,2700,2014-05-01,2014-08-31
  16,350,2014-04-01,2014-08-31
  2,1300,2012-10-01,
  1,950,2014-06-01,2014-06-08
  3,2000,2014-06-01,2014-06-30
  8,3600,2014-07-08,
  6,5400,2014-05-12,
  4,2700,2013-09-01,
  4,2600,2012-06-01,2014-05-31
  4,2700,2012-07-01,2014-04-30
  1,450,2014-04-02,
  4,2700,2014-04-01,2014-04-30
  4,2200,2014-06-01,2014-10-31
CSV


arr_of_arrs = csv.split(/\n\s?+/).map {|l| CSV.parse(l.strip).flatten}

# takes user input as first arg, then converts it to a Date object
input = ARGV[0]
input_date = Date.strptime(input + "-01") rescue Date.strptime('2018-01-01') # default value for testing

headers = arr_of_arrs.shift
length = arr_of_arrs[0].count
unreserved_offices = 0

# takes headers and makes them into keys for row-values
arr_of_arrs.map! do |arr| 
  i = 0
  tmp_hash = {}
  while i < length
    # checks if value is a date, converts to Date object if so
    if headers[i].match(/Day/)
      tmp_hash[headers[i].to_sym] = Date.strptime(arr[i], '%Y-%m-%d') rescue nil
    else
      tmp_hash[headers[i].to_sym] = arr[i]
    end
    i += 1
  end
  # gets total office capacity
  unreserved_offices += tmp_hash[:Capacity].to_i
  tmp_hash
end

days_in_month = {
  1 => 31.0,
  2 => 28.0,
  3 => 31.0,
  4 => 30.0,
  5 => 31.0,
  6 => 30.0,
  7 => 31.0,
  8 => 31.0,
  9 => 30.0,
  10 => 31.0,
  11 => 30.0,
  12 => 31.0
}

# handling leap years
if input_date.leap?
  days_in_month[2] = 29
end

# replaces each office with their expected revenue for the input date
revenue = arr_of_arrs.map do |office|
  if (office[:StartDay] < input_date && office[:EndDay].nil?) || input_date.between?(office[:StartDay], office[:EndDay])
    unreserved_offices -= office[:Capacity].to_i
    #checks if whole month is rented
    if office[:EndDay].nil? || office[:EndDay].month > input_date.month || input_date.next_day.month > input_date.month
      office[:MonthlyPrice].to_i
    else
      # calculates prorated revenue
      (office[:MonthlyPrice].to_i / days_in_month[input_date.month]) * office[:EndDay].mday
    end 
  else
    0
  end
end

# formatting the output correctly
def format_currency(number)
  format("$%.2f",number).sub!(/(\d+)(\d\d\d)/,'\1,\2') || "$0.00"
end

puts "expected revenue: #{format_currency(revenue.reduce(:+))}, expected total capacity of unreserved offices: #{unreserved_offices}\n\n"
