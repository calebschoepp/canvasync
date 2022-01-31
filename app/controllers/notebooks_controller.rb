class NotebooksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notebook, only: %i[ show edit update destroy ]

  # TODO: Actually implement correctly, i.e. create user_notebooks when creating a notebook etc.
  # TODO: Maybe use Pundit for authorization instead of ad-hoc?

  # GET /notebooks or /notebooks.json
  def index
    @notebooks = policy_scope(Notebook)
  end

  # GET /notebooks/1 or /notebooks/1.json
  def show
    authorize @notebook
  end

  # GET /notebooks/new
  def new
    authorize @notebook = Notebook.new
  end

  # GET /notebooks/1/edit
  def edit
    authorize @notebook
  end

  # POST /notebooks or /notebooks.json
  def create
    @notebook = Notebook.new(notebook_params)
    user_notebook = UserNotebook.new
    user_notebook.user = current_user
    user_notebook.notebook = @notebook
    user_notebook.is_owner = true
    @notebook.user_notebooks << user_notebook
    authorize @notebook

    respond_to do |format|
      if @notebook.save
        format.html { redirect_to notebook_url(@notebook), notice: "Notebook was successfully created." }
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
        format.html { redirect_to notebook_url(@notebook), notice: "Notebook was successfully updated." }
        format.json { render :show, status: :ok, location: @notebook }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @notebook.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_notebook
      @notebook = Notebook.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def notebook_params
      params.require(:notebook).permit(:name)
    end
end
