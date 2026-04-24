export const logger = {
  info: (message, context = {}) => {
    console.log(JSON.stringify({ level: 'info', message, ...context }));
  },
  error: (message, context = {}) => {
    console.error(JSON.stringify({ level: 'error', message, ...context }));
  },
};
