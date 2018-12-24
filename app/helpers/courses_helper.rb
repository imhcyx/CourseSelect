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
    
    def get_course_credit(course)
        course.credit.split('/')[1].to_f
    end
    
    def get_course_credits(courses, keyword='')
        courses.
        select {|course| keyword == '' or course['course_type'].include? keyword}.
        sum {|course| get_course_credit(course)}
    end
    
    def get_obtained_credits(grades, keyword='')
        grades.
        select {|grade| keyword == '' or grade.course['course_type'].include? keyword}.
        select {|grade| grade.grade.to_f >= 60}.
        sum {|grade| get_course_credit(grade.course)}
    end
    
end