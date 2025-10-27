/**
 * XyFlow Editor Hook for Phoenix LiveView
 * 
 * This hook initializes a XyFlow node-based editor for the Living Web system.
 * It handles:
 * - Node/edge initialization
 * - Drag and drop events
 * - Connection creation
 * - Communication with the LiveView
 */

import { Editor, createDefaultState } from '@xyflow/system';

const XyflowEditorHook = {
  /**
   * Hook lifecycle: called when the element is mounted to the DOM
   */
  mounted() {
    this.initXyFlow();
  },

  /**
   * Hook lifecycle: called when the element is updated by LiveView
   */
  updated() {
    // Update XyFlow with new nodes/edges from the server
    this.updateXyFlow();
  },

  /**
   * Hook lifecycle: called when the element is removed from the DOM
   */
  destroyed() {
    // Clean up XyFlow instance
    if (this.editor) {
      this.editor.destroy();
    }
  },

  /**
   * Initialize XyFlow on the container element
   */
  initXyFlow() {
    const container = this.el;
    if (!container) {
      console.error('XyflowEditor: Container element not found');
      return;
    }

    // Parse initial nodes and edges from data attributes
    const initialNodes = this.parseDataAttribute('nodes');
    const initialEdges = this.parseDataAttribute('edges');

    console.log('Initializing XyFlow with nodes:', initialNodes);
    console.log('Initializing XyFlow with edges:', initialEdges);

    // Create default state
    const state = createDefaultState();

    // Set initial nodes and edges
    state.nodes.set(initialNodes);
    state.edges.set(initialEdges);

    // Create editor instance
    try {
      this.editor = new Editor({
        container,
        state
      });

      // Make nodes draggable
      this.editor.nodes.draggable = true;
      this.editor.nodes.connectable = true;

      // Set up event listeners
      this.setupEventListeners();
    } catch (error) {
      console.error('Error initializing XyFlow:', error);
    }
  },

  /**
   * Update XyFlow when LiveView sends new data
   */
  updateXyFlow() {
    if (!this.editor) return;

    const newNodes = this.parseDataAttribute('nodes');
    const newEdges = this.parseDataAttribute('edges');

    // Update nodes and edges if they've changed
    if (newNodes) {
      this.editor.setNodes(newNodes);
    }
    if (newEdges) {
      this.editor.setEdges(newEdges);
    }
  },

  /**
   * Set up event listeners for XyFlow interactions
   */
  setupEventListeners() {
    if (!this.editor) return;

    // Listen for node drag end
    this.editor.on('nodeDragStop', (event) => {
      const nodeId = event.id;
      const position = event.position;
      
      this.pushEventToLiveView('node_moved', {
        node_id: nodeId,
        position_x: position.x,
        position_y: position.y
      });
    });

    // Listen for edge creation
    this.editor.on('edgeCreated', (event) => {
      const edge = event.edge;
      
      this.pushEventToLiveView('edge_added', {
        source: edge.source,
        target: edge.target,
        source_handle: edge.sourceHandle,
        target_handle: edge.targetHandle
      });
    });

    // Listen for node click (for selection)
    this.editor.on('nodeClick', (event) => {
      const nodeId = event.id;
      
      this.pushEventToLiveView('node_selected', {
        node_id: nodeId
      });
    });
  },

  /**
   * Parse data attributes from the container element
   * @param {string} attributeName - Name of the data attribute
   * @returns {Object|null} Parsed JSON data or null
   */
  parseDataAttribute(attributeName) {
    const data = this.el.dataset[attributeName];
    if (!data) return null;

    try {
      return JSON.parse(data);
    } catch (error) {
      console.error(`Error parsing ${attributeName} data attribute:`, error);
      return null;
    }
  },

  /**
   * Push an event to the LiveView
   * @param {string} eventName - Name of the event
   * @param {Object} payload - Event data
   */
  pushEventToLiveView(eventName, payload) {
    this.pushEvent(eventName, payload);
  }
};

export default XyflowEditorHook;

