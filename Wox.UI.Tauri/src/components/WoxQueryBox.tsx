import React, { useEffect, useImperativeHandle } from "react"
import styled from "styled-components"
import { WoxTauriHelper } from "../utils/WoxTauriHelper.ts"
import { useVisibilityChange } from "@uidotdev/usehooks"
import { WoxMessageHelper } from "../utils/WoxMessageHelper.ts"
import { WoxMessageMethodEnum } from "../enums/WoxMessageMethodEnum.ts"

export type WoxQueryBoxRefHandler = {
  changeQuery: (query: string) => void
  selectAll: () => void
  focus: () => void
}

export type WoxQueryBoxProps = {
  defaultValue?: string
  onQueryChange: (query: string) => void
}

export default React.forwardRef((_props: WoxQueryBoxProps, ref: React.Ref<WoxQueryBoxRefHandler>) => {
  const queryBoxRef = React.createRef<
    HTMLInputElement
  >()
  const documentVisible = useVisibilityChange()
  useImperativeHandle(ref, () => ({
    changeQuery: (query: string) => {
      if (queryBoxRef.current) {
        queryBoxRef.current!.value = query
        _props.onQueryChange(query)
      }
    },
    selectAll: () => {
      queryBoxRef.current?.select()
    },
    focus: () => {
      queryBoxRef.current?.focus()
    }
  }))

  useEffect(() => {
    // Focus on query box when document is visible
    if (documentVisible) {
      queryBoxRef.current?.focus()

      WoxMessageHelper.getInstance().sendMessage(WoxMessageMethodEnum.ON_VISIBILITY_CHANGED.code, {
        "isVisible": "true",
        "query": queryBoxRef.current?.value || ""
      })
    }
  }, [documentVisible])


  return <Style className="wox-query-box">
    <input ref={queryBoxRef}
           title={"Query Wox"}
           className={"mousetrap"}
           type="text"
           aria-label="Wox"
           autoComplete="off"
           autoCorrect="off"
           autoCapitalize="off"
           defaultValue={_props.defaultValue}
           onChange={(e) => {
             _props.onQueryChange(e.target.value)
           }} />
    <button className={"wox-setting"} onMouseMoveCapture={(event) => {
      WoxTauriHelper.getInstance().startDragging().then(_ => {
        queryBoxRef.current?.focus()
      })
      event.preventDefault()
      event.stopPropagation()
    }}>Wox
    </button>
  </Style>
})

const Style = styled.div`
  position: relative;
  width: ${WoxTauriHelper.getInstance().getWoxWindowWidth()}px;
  overflow: hidden;
  border: ${WoxTauriHelper.getInstance().isTauri() ? "0px" : "1px"} solid #dedede;

  input {
    height: 59px;
    line-height: 59px;
    width: ${WoxTauriHelper.getInstance().getWoxWindowWidth()}px;
    font-size: 24px;
    outline: none;
    padding: 10px;
    border: 0;
    background-color: transparent;
    cursor: auto;
    color: black;
    display: inline-block;
  }

  .wox-setting {
    position: absolute;
    bottom: 3px;
    right: 4px;
    top: 3px;
    padding: 0 10px;
    background: transparent;
    border: none;
    color: #545454;
  }
`