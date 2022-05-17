
export const stringToBytes = (str: string): number[] => {
    return str.split('').map((x) => x.charCodeAt(0));
  };

export function stringToBytesUTF8(str: string): number[] {
    return stringToBytes(encodeURIComponent(str));
  }