import { NativeModules } from 'react-native';

const { RNMisnap } = NativeModules;

export default {
  greet(config):Promise<string> {
    return RNMisnap.greet(config);
  },

  capture(config) {
    return RNMisnap.capture(config);
  },
};
