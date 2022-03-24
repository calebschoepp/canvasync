require 'convert_api'
require './app/lib/accepted_file_types'

class NotebooksController < ApplicationController
  include AcceptedFileTypes

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
    @participant_layers = @notebook.pages.map(&:layers).flatten.filter { |l| l.writer.user.id == current_user.id && !l.writer.is_owner }
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
    if !params[:notebook][:background].nil? && params[:notebook][:background].size < 30.megabytes && (
        params[:notebook][:background].content_type.eql?(PNG_MIME) ||
        JPEG_MIME.include?(params[:notebook][:background].content_type) ||
        POWERPOINT_MIME.include?(params[:notebook][:background].content_type))
      # Convert allowed file types (JPEG, PNG, PowerPoint) that are not PDF to PDF
      content_name = params[:notebook][:background].original_filename
      new_content_name = "#{content_name[...content_name.rindex(/\./)]}.pdf"
      tempfile = Tempfile.new(new_content_name)
      # Generate PDF containing uploaded PowerPoint
      pdf = ConvertApi.convert('pdf', { File: ConvertApi::UploadIO.new(File.open(params[:notebook][:background].tempfile)) })
      pdf.save_files(tempfile.path)
      # Replace uploaded file with its PDF replacement
      params[:notebook][:background] = ActionDispatch::Http::UploadedFile.new({
                                                                                :filename => new_content_name,
                                                                                :type => PDF_MIME,
                                                                                :tempfile => tempfile
                                                                              })
    end

    @notebook = Notebook.new(notebook_params)

    # Setup user_notebook
    user_notebook = UserNotebook.new
    user_notebook.user = current_user
    user_notebook.notebook = @notebook
    user_notebook.is_owner = true
    @notebook.user_notebooks << user_notebook

    if params[:notebook][:background].nil?
      # Create single page and corresponding owner layer when no background is specified
      page = Page.new(number: 1, notebook: @notebook)
      page.layers << Layer.new(page: page, writer: user_notebook)
      @notebook.pages << page
    elsif params[:notebook][:background].content_type.eql?(PDF_MIME)
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
