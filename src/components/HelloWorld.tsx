import './HelloWorld.css'
import VisitCounter from './VisitCounter'

const HelloWorld = () => {
  return (
    <div className="hello-world-container" data-testid="hello-world-container">
      <h1 className="hello-world-text">Hello World</h1>
      <VisitCounter />
    </div>
  )
}

export default HelloWorld
