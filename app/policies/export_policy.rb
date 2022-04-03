class ExportPolicy < ApplicationPolicy
  # Mandated by FR-13: Export.Notebook

  class Scope < Scope
    def resolve
      scope.where(user_id: user.id)
    end
  end

  def index?
    true
  end

  def create?
    record.user_id == user.id
  end

  def destroy?
    record.user_id == user.id
  end
end
