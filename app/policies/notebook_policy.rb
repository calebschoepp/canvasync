class NotebookPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.joins(:user_notebooks).where(:user_notebooks => {user_id: user.id})
    end
  end

  def index?
    true
  end

  def show?
    record.users.pluck(:id).include? user.id
  end

  def new?
    true
  end

  def create?
    user_notebook = record.user_notebooks.first
    user_notebook.user_id == user.id && user_notebook.is_owner
  end

  def update?
    record.is_owner? user
  end
end
