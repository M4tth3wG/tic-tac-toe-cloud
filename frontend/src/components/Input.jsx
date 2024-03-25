import React, { useState } from 'react';

function Input({placeholder, onSubmit}){
  const [inputValue, setInputValue] = useState('');

  const onClick = () => {
    onSubmit(inputValue);
  };

  const handleChange = (event) => {
    setInputValue(event.target.value);
  };

  return (
    <div>
        <input
            type="text"
            value={inputValue}
            onChange={handleChange}
            placeholder={placeholder}
        />
        <button class="submit-button" onClick={onClick}>Submit</button>
    </div>
  );
};

export default Input;