import { Handle, Position } from 'reactflow';

const COLORS = {
  default: { bg: '#F8F8F8', border: '#333333', text: '#666666' },
  selected: { bg: '#E8E8E8', border: '#000000', text: '#000000' },
  hover: { bg: '#F0F0F0', border: '#333333', text: '#333333' }
};

function ProcessNode({ data, selected }) {
  const colors = selected ? COLORS.selected : COLORS.default;

  return (
    <div
      style={{
        background: colors.bg,
        border: `2px solid ${colors.border}`,
        borderRadius: '4px', // Rounded corners for process nodes
        padding: '8px 12px',
        minWidth: '120px',
        color: colors.text,
        fontFamily: "'Geneva', 'Monaco', 'Chicago', system-ui",
        fontSize: '11px',
        fontWeight: '500',
        textAlign: 'center',
        boxShadow: selected ? '0 0 0 2px #000000' : 'none',
        position: 'relative'
      }}
    >
      <Handle
        type="target"
        position={Position.Left}
        style={{ background: '#666666', width: '8px', height: '8px' }}
      />
      <div style={{ marginBottom: '4px', fontSize: '12px', fontWeight: '600' }}>
        {data.label}
      </div>
      <div style={{ fontSize: '9px', opacity: 0.8 }}>
        {data.category}
      </div>
      {data.requirements && (
        <div style={{ fontSize: '8px', opacity: 0.7, marginTop: '2px' }}>
          {data.requirements}
        </div>
      )}
      <Handle
        type="source"
        position={Position.Right}
        style={{ background: '#666666', width: '8px', height: '8px' }}
      />
    </div>
  );
}

export default ProcessNode;

