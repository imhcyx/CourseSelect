class CoursesController < ApplicationController

  include CoursesHelper

  before_action :student_logged_in, only: [:select, :quit, :list, :prompt, :schedule]
  before_action :teacher_logged_in, only: [:new, :create, :edit, :destroy, :update, :open, :close]#add open by qiao
  before_action :logged_in, only: :index

  #-------------------------for teachers----------------------

  def new
    @course=Course.new
  end

  def create
    @course = Course.new(course_params)
    if @course.save
      current_user.teaching_courses<<@course
      redirect_to courses_path, flash: {success: "新课程申请成功"}
    else
      flash[:warning] = "信息填写有误,请重试"
      render 'new'
    end
  end

  def edit
    @course=Course.find_by_id(params[:id])
  end

  def update
    @course = Course.find_by_id(params[:id])
    if @course.update_attributes(course_params)
      flash={:info => "更新成功"}
    else
      flash={:warning => "更新失败"}
    end
    redirect_to courses_path, flash: flash
  end

  def open
    @course=Course.find_by_id(params[:id])
    @course.update_attributes(open: true)
    redirect_to courses_path, flash: {:success => "已经成功开启该课程:#{ @course.name}"}
  end

  def close
    @course=Course.find_by_id(params[:id])
    @course.update_attributes(open: false)
    redirect_to courses_path, flash: {:success => "已经成功关闭该课程:#{ @course.name}"}
  end

  def destroy
    @course=Course.find_by_id(params[:id])
    current_user.teaching_courses.delete(@course)
    @course.destroy
    flash={:success => "成功删除课程: #{@course.name}"}
    redirect_to courses_path, flash: flash
  end

  #-------------------------for students----------------------

  def list
    #-------QiaoCode--------
    @courses = Course.where(:open=>true)
    @course = @courses-current_user.courses
    @course_type = get_course_info(@course, 'course_type')
    @course.select! {|course| course.open}
    @course.select! {|course|
        check_course_time(course, params['course']['course_time']) and
        check_course_type(course, params['course']['course_type']) and
        check_course_keyword(course, params['keyword'])
    } if request.post?
    @course = @course.paginate(page: params[:page], per_page: 10)
  end

  def prompt
    @public_elective_credits = get_course_credits(current_user.courses, '公共选修')
    @public_elective_credits_obtained = get_obtained_credits(current_user.grades, '公共选修')
    @major_credits = get_course_credits(current_user.courses, '专业')
    @major_credits += get_course_credits(current_user.courses, '一级学科')
    @major_credits_obtained = get_obtained_credits(current_user.grades, '专业')
    @major_credits_obtained += get_obtained_credits(current_user.grades, '一级学科')
    @total_credits = get_course_credits(current_user.courses)
    @total_credits_obtained = get_obtained_credits(current_user.grades)
    @selected_course_names = current_user.courses.map {|course| course['name']}
    @obtained_course_names = current_user.grades.select {|grade| grade.grade.to_f >= 60}.map {|grade| grade.course['name']}
  end

  def schedule
    graded_courses = current_user.grades.select {|grade| grade.grade.to_f > 0}.map {|grade| grade.course}
    @schedule = get_schedule(current_user.courses-graded_courses)
  end

  def select
    @course=Course.find_by_id(params[:id])
    course_names = current_user.courses.map {|course| course.name}
    if course_names.include? @course.name
      flash={:warning => "你过去已选择了课程：#{@course.name}"}
      redirect_to list_courses_path, flash: flash
      return
    end
    if @course.limit_num and @course.student_num>=@course.limit_num
      flash={:warning => "课程选课人数已满：#{@course.name}"}
      redirect_to list_courses_path, flash: flash
      return
    end
    graded_courses = current_user.grades.select {|grade| grade.grade.to_f > 0}.map {|grade| grade.course}
    schedule = get_schedule(current_user.courses-graded_courses)
    triple = get_course_time_triple(@course)
    for i in (triple[1])..(triple[2])
      if (schedule[triple[0]][i])
        flash={:warning => "待选课程：#{@course.name} 与已选课程：#{schedule[triple[0]][i].name} 时间冲突"}
        redirect_to list_courses_path, flash: flash
        return
      end
    end
    @course.update_attributes(student_num: @course.student_num+1)
    current_user.courses<<@course
    flash={:success => "成功选择课程: #{@course.name}"}
    redirect_to courses_path, flash: flash
  end

  def quit
    @course=Course.find_by_id(params[:id])
    current_user.courses.delete(@course)
    @course.update_attributes(student_num: @course.student_num-1)
    flash={:success => "成功退选课程: #{@course.name}"}
    redirect_to courses_path, flash: flash
  end


  #-------------------------for both teachers and students----------------------

  def index
    @course=current_user.teaching_courses.paginate(page: params[:page], per_page: 10) if teacher_logged_in?
    @course=current_user.courses.paginate(page: params[:page], per_page: 10) if student_logged_in?
  end


  private

  # Confirms a student logged-in user.
  def student_logged_in
    unless student_logged_in?
      redirect_to root_url, flash: {danger: '请登陆'}
    end
  end

  # Confirms a teacher logged-in user.
  def teacher_logged_in
    unless teacher_logged_in?
      redirect_to root_url, flash: {danger: '请登陆'}
    end
  end

  # Confirms a  logged-in user.
  def logged_in
    unless logged_in?
      redirect_to root_url, flash: {danger: '请登陆'}
    end
  end

  def course_params
    params.require(:course).permit(:course_code, :name, :course_type, :teaching_type, :exam_type,
                                   :credit, :limit_num, :class_room, :course_time, :course_week)
  end


end
