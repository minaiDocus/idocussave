class PackPieceSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :name, :content_text, :detected_third_party_id, :pre_assignment_state
end