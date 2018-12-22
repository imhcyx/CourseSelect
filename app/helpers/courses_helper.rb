module CoursesHelper
    
    def date_transform(date)
        return '1' if date.include? "周一"
        return '2' if date.include? "周二"
        return '3' if date.include? "周三"
        return '4' if date.include? "周四"
        return '5' if date.include? "周五"
        return '6' if date.include? "周六"
        return '7' if date.include? "周天"
    end
    
    def get_course_info(courses, type)
        courses.map {|course| course[type]} .sort.uniq
    end
    
    def check_course_time(course, value)
        value == '' or date_transform(course['course_time']) == value
    end
    
    def check_course_type(course, value)
        value == '' or course['course_type'] == value
    end
    
    def check_course_keyword(course, value)
        value.nil? or value == '' or course['name'].include? value
    end
    
end