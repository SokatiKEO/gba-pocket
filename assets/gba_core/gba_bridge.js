/**
 * GBA Web/Mobile Bridge for Flutter
 * High-performance integration layer connecting Flutter and GBA.js core
 */

(function() {
  window.GbaBridge = {
    gba: null,
    canvas: null,
    fps: 60,
    frameCount: 0,
    lastFpsCheck: 0,
    speedMultiplier: 1,
    currentRomName: '',
    isPaused: false,
    isLoaded: false,
    volume: 1.0,
    _drawHookAttached: false,

    _hookDrawCallback: function() {
      if (!this.gba || !this.gba.video) return;
      var self = this;
      var originalDraw = this.gba.video.drawCallback;
      this.gba.video.drawCallback = function() {
        if (originalDraw) originalDraw();
        self.frameCount++;
        var now = performance.now();
        if (now - self.lastFpsCheck >= 1000) {
          self.fps = Math.round((self.frameCount * 1000) / (now - self.lastFpsCheck));
          self.frameCount = 0;
          self.lastFpsCheck = now;
          if (window.onGbaFpsUpdate) {
            window.onGbaFpsUpdate(self.fps);
          }
        }
      };
    },

    init: function(canvasElement) {
      if (this.gba) {
        if (canvasElement && this.canvas !== canvasElement) {
          this.canvas = canvasElement;
          this.gba.setCanvas(canvasElement);
          this._hookDrawCallback();
        }
        return true;
      }

      try {
        var canvas = canvasElement || document.getElementById('gba-canvas');
        if (!canvas) {
          console.warn("[GBA Bridge] Canvas element not provided or found yet.");
          return false;
        }

        this.canvas = canvas;
        this.gba = new GameBoyAdvance();
        this.gba.setCanvas(canvas);

        var bios = window.biosBin || (typeof biosBin !== 'undefined' ? biosBin : null);
        if (bios) {
          this.gba.setBios(bios, false);
        }

        // Configure audio
        this.gba.audio.masterEnable = true;
        this.gba.audio.masterVolume = this.volume;

        // Custom draw callback to calculate real-time FPS
        this._hookDrawCallback();

        // Resume AudioContext on any user gesture
        var unlockAudio = function() {
          if (self.gba && self.gba.audio && self.gba.audio.context) {
            if (self.gba.audio.context.state !== 'running') {
              self.gba.audio.context.resume();
            }
          }
          window.removeEventListener('click', unlockAudio);
          window.removeEventListener('touchstart', unlockAudio);
        };
        window.addEventListener('click', unlockAudio, { passive: true });
        window.addEventListener('touchstart', unlockAudio, { passive: true });

        console.log("[GBA Bridge] Core initialized successfully!");
        return true;
      } catch (e) {
        console.error("[GBA Bridge] Initialization failed:", e);
        return false;
      }
    },

    loadRomFromUrl: function(url, title) {
      if (!this.gba) {
        var ok = this.init();
        if (!ok) return false;
      }
      var self = this;
      var xhr = new XMLHttpRequest();
      xhr.open('GET', url, true);
      xhr.responseType = 'arraybuffer';
      xhr.onload = function() {
        if (xhr.status === 200 || xhr.response) {
          self.loadRomBuffer(xhr.response, title || url.split('/').pop());
        } else {
          console.error("[GBA Bridge] Failed to load ROM from URL:", url, xhr.status);
        }
      };
      xhr.onerror = function(err) {
        console.error("[GBA Bridge] Network error loading ROM:", err);
      };
      xhr.send();
    },

    loadRomBase64: function(base64Data, title) {
      if (!this.gba) {
        var ok = this.init();
        if (!ok) return false;
      }
      try {
        var binaryString = window.atob(base64Data);
        var len = binaryString.length;
        var bytes = new Uint8Array(len);
        for (var i = 0; i < len; i++) {
          bytes[i] = binaryString.charCodeAt(i);
        }
        this.loadRomBuffer(bytes.buffer, title);
      } catch (e) {
        console.error("[GBA Bridge] Error decoding base64 ROM:", e);
      }
    },

    loadRomBuffer: function(buffer, title) {
      if (!this.gba) {
        var ok = this.init();
        if (!ok) return false;
      }
      var self = this;
      try {
        this.gba.pause();

        var success = this.gba.setRom(buffer);
        if (success) {
          self.currentRomName = title || (self.gba.rom ? self.gba.rom.title : "GBA Game");
          self.isLoaded = true;
          self.isPaused = false;
          
          // Resume Audio Context
          if (self.gba.audio && self.gba.audio.context && self.gba.audio.context.state !== 'running') {
            self.gba.audio.context.resume();
          }

          self.gba.runStable();

          if (window.onGbaRomLoaded) {
            window.onGbaRomLoaded(self.currentRomName);
          }
          console.log("[GBA Bridge] Started ROM:", self.currentRomName);
        } else {
          console.error("[GBA Bridge] Failed to parse ROM binary!");
          if (window.onGbaError) {
            window.onGbaError("Failed to parse ROM binary format.");
          }
        }
      } catch (err) {
        console.error("[GBA Bridge] Exception during ROM load:", err && err.stack ? err.stack : err);
      }
    },

    play: function() {
      if (!this.gba || !this.isLoaded) return;
      if (this.gba.audio && this.gba.audio.context && this.gba.audio.context.state !== 'running') {
        this.gba.audio.context.resume();
      }
      this.gba.runStable();
      this.isPaused = false;
    },

    pause: function() {
      if (!this.gba) return;
      this.gba.pause();
      this.isPaused = true;
    },

    togglePause: function() {
      if (this.isPaused) {
        this.play();
      } else {
        this.pause();
      }
      return this.isPaused;
    },

    reset: function() {
      if (!this.gba) return;
      this.gba.pause();
      this.gba.reset();
      if (this.isLoaded) {
        this.gba.runStable();
        this.isPaused = false;
      }
    },

    getKeyIndex: function(keyName) {
      if (!this.gba || !this.gba.keypad) return -1;
      var keypad = this.gba.keypad;
      switch (keyName.toUpperCase()) {
        case 'A': return keypad.A;
        case 'B': return keypad.B;
        case 'SELECT': return keypad.SELECT;
        case 'START': return keypad.START;
        case 'RIGHT': return keypad.RIGHT;
        case 'LEFT': return keypad.LEFT;
        case 'UP': return keypad.UP;
        case 'DOWN': return keypad.DOWN;
        case 'R': return keypad.R;
        case 'L': return keypad.L;
        default: return -1;
      }
    },

    buttonDown: function(keyName) {
      var idx = this.getKeyIndex(keyName);
      if (idx !== -1) {
        this.gba.keypad.currentDown &= ~(1 << idx);
      }
    },

    buttonUp: function(keyName) {
      var idx = this.getKeyIndex(keyName);
      if (idx !== -1) {
        this.gba.keypad.currentDown |= (1 << idx);
      }
    },

    setVolume: function(vol) {
      this.volume = Math.max(0, Math.min(1, vol));
      if (this.gba && this.gba.audio) {
        this.gba.audio.masterVolume = this.volume;
      }
    },

    setMute: function(muted) {
      if (this.gba && this.gba.audio) {
        this.gba.audio.masterEnable = !muted;
      }
    },

    setSpeed: function(multiplier) {
      this.speedMultiplier = multiplier;
      if (this.gba) {
        // Default GBA throttle is ~16ms (60 FPS).
        // 2x -> 8ms, 3x -> 5ms, 4x -> 4ms
        var targetMs = Math.max(2, Math.round(16 / multiplier));
        this.gba.throttle = targetMs;
      }
    },

    bufToB64: function(buffer) {
      if (!buffer) return null;
      var bytes = buffer instanceof Uint8Array ? buffer : new Uint8Array(buffer.buffer || buffer);
      var binary = '';
      var len = bytes.byteLength;
      var chunkSize = 0x8000;
      for (var i = 0; i < len; i += chunkSize) {
        binary += String.fromCharCode.apply(null, bytes.subarray(i, Math.min(i + chunkSize, len)));
      }
      return window.btoa(binary);
    },

    b64ToBuf: function(base64) {
      if (!base64) return null;
      var binary = window.atob(base64);
      var len = binary.length;
      var bytes = new Uint8Array(len);
      for (var i = 0; i < len; i++) {
        bytes[i] = binary.charCodeAt(i);
      }
      return bytes.buffer;
    },

    exportStateString: function(slot) {
      if (!this.gba || !this.isLoaded) return null;
      try {
        var frozen = this.gba.freeze();
        var serialized = {
          version: 1,
          timestamp: Date.now(),
          romName: this.currentRomName,
          cpu: frozen.cpu,
          irq: frozen.irq,
          audio: frozen.audio,
          mmu: {
            ram: this.bufToB64(frozen.mmu.ram),
            iram: this.bufToB64(frozen.mmu.iram)
          },
          io: {
            registers: this.bufToB64(frozen.io.registers)
          },
          video: {
            inHblank: frozen.video.inHblank,
            inVblank: frozen.video.inVblank,
            vcounter: frozen.video.vcounter,
            vblankIRQ: frozen.video.vblankIRQ,
            hblankIRQ: frozen.video.hblankIRQ,
            vcounterIRQ: frozen.video.vcounterIRQ,
            vcountSetting: frozen.video.vcountSetting,
            vcount: frozen.video.vcount,
            lastHblank: frozen.video.lastHblank,
            nextHblank: frozen.video.nextHblank,
            nextEvent: frozen.video.nextEvent,
            nextHblankIRQ: frozen.video.nextHblankIRQ,
            nextVblankIRQ: frozen.video.nextVblankIRQ,
            nextVcounterIRQ: frozen.video.nextVcounterIRQ,
            renderPath: frozen.video.renderPath ? {
              palette: this.bufToB64(frozen.video.renderPath.palette),
              vram: this.bufToB64(frozen.video.renderPath.vram),
              oam: this.bufToB64(frozen.video.renderPath.oam)
            } : null
          }
        };
        var jsonStr = JSON.stringify(serialized);
        try {
          var key = 'gba_save_state_' + (this.currentRomName || 'default') + '_' + (slot || 0);
          localStorage.setItem(key, jsonStr);
        } catch (_) {}
        return jsonStr;
      } catch (e) {
        console.error("[GBA Bridge] Error exporting state:", e);
        return null;
      }
    },

    importStateString: function(jsonStr) {
      if (!this.gba || !this.isLoaded || !jsonStr) return false;
      try {
        var serialized = typeof jsonStr === 'string' ? JSON.parse(jsonStr) : jsonStr;
        var frost = {
          cpu: serialized.cpu,
          irq: serialized.irq,
          audio: serialized.audio,
          mmu: {
            ram: this.b64ToBuf(serialized.mmu.ram),
            iram: this.b64ToBuf(serialized.mmu.iram)
          },
          io: {
            registers: this.b64ToBuf(serialized.io.registers)
          },
          video: {
            inHblank: serialized.video.inHblank,
            inVblank: serialized.video.inVblank,
            vcounter: serialized.video.vcounter,
            vblankIRQ: serialized.video.vblankIRQ,
            hblankIRQ: serialized.video.hblankIRQ,
            vcounterIRQ: serialized.video.vcounterIRQ,
            vcountSetting: serialized.video.vcountSetting,
            vcount: serialized.video.vcount,
            lastHblank: serialized.video.lastHblank,
            nextHblank: serialized.video.nextHblank,
            nextEvent: serialized.video.nextEvent,
            nextHblankIRQ: serialized.video.nextHblankIRQ,
            nextVblankIRQ: serialized.video.nextVblankIRQ,
            nextVcounterIRQ: serialized.video.nextVcounterIRQ,
            renderPath: serialized.video.renderPath ? {
              palette: this.b64ToBuf(serialized.video.renderPath.palette),
              vram: this.b64ToBuf(serialized.video.renderPath.vram),
              oam: this.b64ToBuf(serialized.video.renderPath.oam)
            } : null
          }
        };
        this.gba.defrost(frost);
        if (!this.isPaused) {
          if (this.gba.audio && this.gba.audio.context && this.gba.audio.context.state !== 'running') {
            this.gba.audio.context.resume();
          }
          this.gba.runStable();
        }
        console.log("[GBA Bridge] State successfully imported and resumed!");
        return true;
      } catch (e) {
        console.error("[GBA Bridge] Error importing state string:", e);
        return false;
      }
    },

    saveState: function(slot) {
      var stateStr = this.exportStateString(slot);
      return stateStr !== null;
    },

    loadState: function(slot) {
      if (!this.gba || !this.isLoaded) return false;
      try {
        var key = 'gba_save_state_' + (this.currentRomName || 'default') + '_' + slot;
        var data = localStorage.getItem(key);
        if (!data) return false;
        return this.importStateString(data);
      } catch (e) {
        return false;
      }
    },

    hasSaveState: function(slot) {
      var key = 'gba_save_state_' + (this.currentRomName || 'default') + '_' + slot;
      return localStorage.getItem(key) !== null;
    },

    exportBatterySaveBase64: function() {
      if (!this.gba || !this.gba.mmu || !this.gba.mmu.save) return null;
      try {
        return this.gba.encodeBase64(this.gba.mmu.save.view);
      } catch (e) {
        return null;
      }
    },

    importBatterySaveBase64: function(base64Data) {
      if (!this.gba) return false;
      try {
        this.gba.decodeSavedata(base64Data);
        return true;
      } catch (e) {
        return false;
      }
    }
  };

  // Persistent ROM storage backed by IndexedDB
  window.GbaRomDb = {
    _dbPromise: null,
    _getDb: function() {
      if (this._dbPromise) return this._dbPromise;
      this._dbPromise = new Promise(function(resolve, reject) {
        if (!window.indexedDB) {
          reject(new Error("IndexedDB is not supported"));
          return;
        }
        var req = window.indexedDB.open('GbaRomDatabase', 1);
        req.onupgradeneeded = function(e) {
          var db = e.target.result;
          if (!db.objectStoreNames.contains('roms')) {
            db.createObjectStore('roms', { keyPath: 'id' });
          }
        };
        req.onsuccess = function(e) {
          resolve(e.target.result);
        };
        req.onerror = function(e) {
          reject(e.target.error);
        };
      });
      return this._dbPromise;
    },

    saveRom: function(id, base64) {
      return this._getDb().then(function(db) {
        return new Promise(function(resolve, reject) {
          var tx = db.transaction('roms', 'readwrite');
          var store = tx.objectStore('roms');
          store.put({ id: id, data: base64, timestamp: Date.now() });
          tx.oncomplete = function() { resolve(true); };
          tx.onerror = function(e) { reject(e.target.error); };
        });
      });
    },

    loadRom: function(id) {
      return this._getDb().then(function(db) {
        return new Promise(function(resolve, reject) {
          var tx = db.transaction('roms', 'readonly');
          var store = tx.objectStore('roms');
          var req = store.get(id);
          req.onsuccess = function(e) {
            var item = e.target.result;
            if (item && item.data) {
              resolve(item.data);
            } else {
              resolve(null);
            }
          };
          req.onerror = function(e) { reject(e.target.error); };
        });
      });
    },

    deleteRom: function(id) {
      return this._getDb().then(function(db) {
        return new Promise(function(resolve, reject) {
          var tx = db.transaction('roms', 'readwrite');
          var store = tx.objectStore('roms');
          store.delete(id);
          tx.oncomplete = function() { resolve(true); };
          tx.onerror = function(e) { reject(e.target.error); };
        });
      });
    }
  };
})();
