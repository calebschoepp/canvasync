class ExportsController < ApplicationController
  before_action :set_export, only: %i[destroy]
  before_action :set_notebook, only: %i[index create]

  # GET /notebooks/1/exports or /notebookes/1/exports.json
  def index
    @exports = policy_scope(@notebook.exports).order(updated_at: :desc) # TODO: Check ordering
    @export = Export.new
  end

  # POST /notebooks/1/exports or /exports.json
  def create
    @export = Export.new(export_params)
    @export.ready = false
    authorize @export

    respond_to do |format|
      if @export.save
        ExportNotebookJob.perform_later(@export.id)
        format.html { redirect_to export_url(@export), notice: 'Export was successfully created.' }
        format.json { render :show, status: :created, location: @export }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @export.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /exports/1 or /exports/1.json
  def destroy
    notebook = @export.notebook
    authorize @export
    @export.destroy!

    respond_to do |format|
      format.html { redirect_to notebook_exports_url(notebook), notice: 'Export was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_export
    @export = Export.find(params[:id])
  end

  def set_notebook
    @notebook = Notebook.find(params[:notebook_id])
  end

  # Only allow a list of trusted parameters through.
  def export_params
    params.require(:export).permit(:notebook_id, :user_id)
  end
end
