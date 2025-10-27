import { Handle, Position } from 'reactflow';

const COLORS = {
  default: { bg: '#F8F8F8', border: '#333333', text: '#666666' },
  selected: { bg: '#E8E8E8', border: '#000000', text: '#000000' },
  hover: { bg: '#F0F0F0', border: '#333333', text: '#333333' }
};

function SourceNode({ data, selected }) {
  const colors = selected ? COLORS.selected : COLORS.default;

  return (
    <div
      style={{
        background: colors.bg,
        border: `2px solid ${colors.border}`,
        borderRadius: '50%', // Circle for source nodes
        width: '100px',
        height: '100px',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'center',
        alignItems: 'center',
        color: colors.text,
        fontFamily: "'Geneva', 'Monaco', 'Chicago', system-ui",
        fontSize: '10px',
        fontWeight: '500',
        textAlign: 'center',
        boxShadow: selected ? '0 0 0 2px #000000' : 'none',
        padding: '8px'
      }}
    >
      <div style={{ marginBottom: '4px', fontSize: '11px', fontWeight: '600' }}>
        {data.label}
      </div>
      <div style={{ fontSize: '8px', opacity: 0.8 }}>
        {data.category}
      </div>
      <Handle
        type="source"
        position={Position.Right}
        style={{ background: '#666666', width: '8px', height: '8px' }}
      />
    </div>
  );
}

export default SourceNode;

