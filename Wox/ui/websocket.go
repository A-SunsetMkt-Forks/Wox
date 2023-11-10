package ui

import (
	"context"
	"encoding/json"
	"fmt"
	"github.com/olahol/melody"
	"net/http"
	"os"
	"strings"
	"time"
	"wox/plugin"
	"wox/setting"
	"wox/util"
)

var m *melody.Melody
var uiConnected = false

type websocketMsgType string

const (
	WebsocketMsgTypeRequest  websocketMsgType = "WebsocketMsgTypeRequest"
	WebsocketMsgTypeResponse websocketMsgType = "WebsocketMsgTypeResponse"
)

type WebsocketMsg struct {
	Id      string
	Type    websocketMsgType
	Method  string
	Success bool
	Data    any
}

type RestResponse struct {
	Success bool
	Message string
	Data    any
}

func writeSuccessResponse(w http.ResponseWriter, data any) {
	d, marshalErr := json.Marshal(RestResponse{
		Success: true,
		Message: "",
		Data:    data,
	})
	if marshalErr != nil {
		writeErrorResponse(w, marshalErr.Error())
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write(d)
}

func writeErrorResponse(w http.ResponseWriter, errMsg string) {
	d, _ := json.Marshal(RestResponse{
		Success: false,
		Message: errMsg,
		Data:    "",
	})

	w.Header().Set("Content-Type", "application/json")
	w.Write(d)
}

func enableCors(w http.ResponseWriter) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
}

func serveAndWait(ctx context.Context, port int) {
	m = melody.New()
	m.Config.MaxMessageSize = 1024 * 1024 * 10 // 10MB
	m.Config.MessageBufferSize = 1024 * 1024   // 1MB

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		writeSuccessResponse(w, "Wox")
	})

	http.HandleFunc("/image", func(w http.ResponseWriter, r *http.Request) {
		id := r.URL.Query().Get("id")
		if id == "" {
			w.Write([]byte("no id"))
			return
		}

		imagePath, ok := plugin.GetLocalImageMap(id)
		if !ok {
			w.Write([]byte("no image"))
			return
		}

		if _, statErr := os.Stat(imagePath); os.IsNotExist(statErr) {
			w.Write([]byte("image not exist"))
			return
		}

		w.Header().Set("Cache-Control", "public, max-age=3600")
		http.ServeFile(w, r, imagePath)
	})

	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		m.HandleRequest(w, r)
	})

	http.HandleFunc("/theme", func(w http.ResponseWriter, r *http.Request) {
		enableCors(w)
		theme := GetUIManager().GetCurrentTheme(util.NewTraceContext())
		writeSuccessResponse(w, theme)
	})

	http.HandleFunc("/setting/wox", func(w http.ResponseWriter, r *http.Request) {
		enableCors(w)

		woxSetting := setting.GetSettingManager().GetWoxSetting(util.NewTraceContext())
		writeSuccessResponse(w, woxSetting)
	})

	http.HandleFunc("/setting/wox/update", func(w http.ResponseWriter, r *http.Request) {
		enableCors(w)

		decoder := json.NewDecoder(r.Body)
		var woxSetting setting.WoxSetting
		err := decoder.Decode(&woxSetting)
		if err != nil {
			w.Header().Set("code", "500")
			w.Write([]byte(err.Error()))
			return
		}

		updateErr := setting.GetSettingManager().UpdateWoxSetting(util.NewTraceContext(), woxSetting)
		if updateErr != nil {
			w.Header().Set("code", "500")
			w.Write([]byte(updateErr.Error()))
			return
		}

		writeSuccessResponse(w, "")
	})

	m.HandleConnect(func(s *melody.Session) {
		if !uiConnected {
			uiConnected = true
			logger.Info(ctx, fmt.Sprintf("ui connected: %s", s.Request.RemoteAddr))

			util.Go(ctx, "post app start", func() {
				time.Sleep(time.Millisecond * 500) // wait for ui to be ready
				GetUIManager().PostAppStart(util.NewTraceContext())
			})
		}
	})

	m.HandleMessage(func(s *melody.Session, msg []byte) {
		ctxNew := util.NewTraceContext()

		logger.Info(ctxNew, fmt.Sprintf("got request from ui: %s", string(msg)))

		if strings.Contains(string(msg), string(WebsocketMsgTypeRequest)) {
			var request WebsocketMsg
			unmarshalErr := json.Unmarshal(msg, &request)
			if unmarshalErr != nil {
				logger.Error(ctxNew, fmt.Sprintf("failed to unmarshal websocket request: %s", unmarshalErr.Error()))
				return
			}
			util.Go(ctxNew, "handle ui query", func() {
				onUIRequest(ctxNew, request)
			})
		}
	})

	logger.Info(ctx, fmt.Sprintf("websocket server start at：ws://localhost:%d", port))
	err := http.ListenAndServe(fmt.Sprintf("localhost:%d", port), nil)
	if err != nil {
		logger.Error(ctx, fmt.Sprintf("failed to start server: %s", err.Error()))
	}
}

func requestUI(ctx context.Context, request WebsocketMsg) {
	request.Type = WebsocketMsgTypeRequest
	marshalData, marshalErr := json.Marshal(request)
	if marshalErr != nil {
		logger.Error(ctx, fmt.Sprintf("failed to marshal websocket request: %s", marshalErr.Error()))
		return
	}

	jsonData, _ := json.Marshal(request.Data)
	util.GetLogger().Info(ctx, fmt.Sprintf("[->UI] %s: %s", request.Method, jsonData))
	m.Broadcast(marshalData)
}

func responseUI(ctx context.Context, response WebsocketMsg) {
	response.Type = WebsocketMsgTypeResponse
	marshalData, marshalErr := json.Marshal(response)
	if marshalErr != nil {
		logger.Error(ctx, fmt.Sprintf("failed to marshal websocket response: %s", marshalErr.Error()))
		return
	}
	m.Broadcast(marshalData)
}

func responseUISuccessWithData(ctx context.Context, request WebsocketMsg, data any) {
	responseUI(ctx, WebsocketMsg{
		Id:      request.Id,
		Type:    WebsocketMsgTypeResponse,
		Method:  request.Method,
		Success: true,
		Data:    data,
	})
}

func responseUISuccess(ctx context.Context, request WebsocketMsg) {
	responseUISuccessWithData(ctx, request, nil)
}

func responseUIError(ctx context.Context, request WebsocketMsg, errMsg string) {
	responseUI(ctx, WebsocketMsg{
		Id:      request.Id,
		Type:    WebsocketMsgTypeResponse,
		Method:  request.Method,
		Success: false,
		Data:    errMsg,
	})
}
