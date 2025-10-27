const ChatFormHook = {
  mounted() {
    console.log("ChatFormHook: mounted", this.el);
    
    const submitMessage = () => {
      const input = this.el.querySelector("#chat-message-input");
      if (!input) {
        console.error("ChatForm: Input not found");
        return;
      }

      const message = input.value.trim();
      if (!message) return;

      console.log("ChatForm: Submitting message:", message);

      // Use the hook's built-in pushEvent method - this will push to the connected LiveView
      this.pushEvent("send_message", { message: message }, (reply, ref) => {
        console.log("ChatForm: Event sent, reply:", reply);
      });

      // Clear the input immediately (optimistic update)
      input.value = "";
      console.log("ChatForm: Input cleared");
    };

    // Add keydown listener to input
    const input = this.el.querySelector("#chat-message-input");
    if (input) {
      input.addEventListener("keydown", (event) => {
        if (event.key === "Enter" && !event.shiftKey) {
          event.preventDefault();
          submitMessage();
        }
      });
    }

    // Handle send button click
    const sendButton = this.el.querySelector('button[type="button"]');
    if (sendButton) {
      sendButton.addEventListener("click", () => {
        submitMessage();
      });
    }
  },

  updated() {
    // Re-attach event listeners after an update
    const container = this.el;
    const submitMessage = () => {
      const input = container.querySelector("#chat-message-input");
      if (!input) return;

      const message = input.value.trim();
      if (!message) return;

      if (window.liveSocket) {
        window.liveSocket.pushEvent("send_message", { message: message });
        input.value = "";
      }
    };

    const sendButton = container.querySelector('button[type="button"]');
    if (sendButton) {
      sendButton.addEventListener("click", submitMessage);
    }
  }
};

export default ChatFormHook;

