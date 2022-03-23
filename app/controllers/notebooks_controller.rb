class NotebooksController < ApplicationController
  PDF = 'application/pdf'.freeze
  PNG = 'image/png'.freeze
  PPT = %w[application/vnd.ms-powerpoint application/vnd.openxmlformats-officedocument.presentationml.presentation].freeze
  JPEG = %w[image/jpg image/jpeg].freeze

  before_action :set_notebook, only: %i[show edit update destroy preview join]

  # GET /notebooks or /notebooks.json
  def index
    @notebooks = policy_scope(Notebook)
    @owned_notebooks = @notebooks.select do |notebook|
      notebook.owner? current_user
    end
    @joined_notebooks = @notebooks.reject do |notebook|
      notebook.owner? current_user
    end
  end

  # GET /notebooks/1 or /notebooks/1.json
  def show
    authorize @notebook
    # TODO: Support multiple pages
    @owner_layers = @notebook.pages.map(&:layers).flatten.filter { |l| l.writer.is_owner }
    @participant_layers = @notebook.pages.map(&:layers).flatten.filter { |l| l.writer.id == current_user.id && !l.writer.is_owner }
  end

  # GET /notebooks/new
  def new
    authorize @notebook = Notebook.new
  end

  # GET /notebooks/1/edit
  def edit
    authorize @notebook
  end

  # GET /notebooks/1/preview
  def preview
    authorize @notebook
    if @notebook.owner?(current_user)
      redirect_to notebooks_url, flash: { alert: 'You are already an owner of this notebook' }
    elsif @notebook.participant?(current_user)
      redirect_to notebooks_url, flash: { alert: 'You are already a participant of this notebook' }
    end
  end

  # POST /notebooks or /notebooks.json
  def create
    @notebook = Notebook.new(notebook_params)

    # Setup user_notebook
    user_notebook = UserNotebook.new
    user_notebook.user = current_user
    user_notebook.notebook = @notebook
    user_notebook.is_owner = true
    @notebook.user_notebooks << user_notebook

    puts "\n\nNOTEBOOK TYPE: #{params[:notebook][:background].content_type}"

    if params[:notebook][:background].nil?
      # Create single page and corresponding owner layer when no background is specified
      page = Page.new(number: 1, notebook: @notebook)
      page.layers << Layer.new(page: page, writer: user_notebook)
      @notebook.pages << page
    else
      content_type = params[:notebook][:background].content_type
      content_name = params[:notebook][:background].original_filename
      if content_type.eql?(PNG) || JPEG.include?(content_type)
        File.open(params[:notebook][:background].tempfile, 'r') do |f|
          f.binmode
          pdf = Prawn::Document.new(:background => content_name,
                                    :page_size => "LETTER",
                                    :page_layout => :portrait,
                                    :margin => 0)
          content_name = "#{content_name[...content_name.rindex(/\./)]}.pdf"
          pdf.render_file(content_name)
          params[:notebook][:background].tempfile = content_name
        end
      elsif PPT.include?(params[:notebook][:background].content_type)
        puts "PPT FILE UPLOADED"
      elsif PDF
        puts "PDF Uploaded"
      else
        puts "INvalid file"
      end

      # Create page and corresponding owner layer for each page in uploaded file
      File.open(params[:notebook][:background].tempfile, 'r') do |f|
        f.binmode
        r = PDF::Reader.new f
        r.pages.each_with_index do |_pdf_page, i|
          page = Page.new(number: i + 1, notebook: @notebook)
          page.layers << Layer.new(page: page, writer: user_notebook)
          @notebook.pages << page
        end
      end
    end

    authorize @notebook

    respond_to do |format|
      if @notebook.save
        format.html { redirect_to notebook_url(@notebook), notice: 'Notebook was successfully created.' }
        format.json { render :show, status: :created, location: @notebook }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @notebook.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /notebooks/1 or /notebooks/1.json
  def update
    authorize @notebook
    respond_to do |format|
      if @notebook.update(notebook_params)
        format.html { redirect_to notebooks_url, notice: 'Notebook was successfully updated.' }
        format.json { render :show, status: :ok, location: @notebook }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @notebook.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /notebooks/1/join /notebooks/1/join.json
  def join
    authorize @notebook

    if @notebook.owner?(current_user)
      redirect_to notebooks_url, flash: { alert: 'You are already an owner of this notebook' }
      return
    elsif @notebook.participant?(current_user)
      redirect_to notebooks_url, flash: { alert: 'You are already a participant of this notebook' }
      return
    end

    # Setup user_notebook
    user_notebook = UserNotebook.new
    user_notebook.user = current_user
    user_notebook.notebook = @notebook
    user_notebook.is_owner = false
    @notebook.user_notebooks << user_notebook

    # Setup layer(s) for participant
    @notebook.pages.each do |page|
      page.layers << Layer.new(page: page, writer: user_notebook)
    end
    respond_to do |format|
      if @notebook.save
        format.html { redirect_to notebook_url(@notebook), notice: "You've joined #{@notebook.name}." }
        format.json { render :show, status: :ok, location: @notebook }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @notebook.errors, status: :unprocessable_entity }
      end
    end
  end

  def search
    @query = params[:query]
    @notebooks = policy_scope(Notebook.where('name LIKE ?', "%#{@query}%"))
    @notebooks = Notebook.none if @query.blank?
    authorize @notebooks
    respond_to do |format|
      format.html { render :search, layout: false }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_notebook
    @notebook = Notebook.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def notebook_params
    params.require(:notebook).permit(:name, :background, :query)
  end
end
